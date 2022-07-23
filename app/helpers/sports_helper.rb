module SportsHelper
  def mlb_game_state(team_id, game)
    is_home = game['teams']['home']['team']['id'].to_i == team_id

    away_score = game['teams']['away']['score']
    home_score = game['teams']['home']['score']

    if away_score.nil? || home_score.nil?
      return "Unknown"
    end

    if away_score == home_score
      return "Tie"
    end

    if ['Final', 'Completed Early', 'Game Over'].include? game['status']['detailedState']
      if is_home
        home_score > away_score ? "Win" : "Loss"
      else
        away_score > home_score ? "Win" : "Loss"
      end
    elsif game['status']['detailedState'] == "In Progress"
      if is_home
        home_score > away_score ? "Winning" : "Losing"
      else
        away_score > home_score ? "Winning" : "Losing"
      end
    else
      "N/A"
    end
  end

  # Total innings for a game
  def total_innings(line_score)
    line_score['scheduledInnings'] > (line_score['currentInning'] || 0) ? line_score['scheduledInnings'] : line_score['currentInning']
  end

  # Determines the class to use to render the play
  def play_class(play)
    run = play['details']['description'].include? 'run(s)'

    return "ball" if play['details']['isBall']
    return "strike" if play['details']['isStrike']
    return "in-play #{run ? "bold" : ""}" if play['details']['isInPlay']
    return "pickoff" if play['type'] == 'pickoff'

    ""
  end

  # Find the class to use for player movement
  def movement_class(event)
    return "in-play" if event['details']['isScoringEvent']
    return "strike" if event['movement']['end'].nil?

    "pickoff"
  end

  def batting_class(result)
    result ||= "N/A"

    return "in-play" if ["Grand Slam", "Home Run", "Triple", "Double", "Single", "Sac Fly", "Sac Bunt", "Field Error", "Fielders Choice"].include? result
    return "strike" if result.downcase.include?("out") || result.include?("DP") || result.include?("Double Play")
    return "ball" if ["Hit By Pitch", "Walk", "Intent Walk"].include? result

    "pickoff"
  end

  # Finds the game status for a given game
  def game_status(game)
    line_score = game['liveData'].nil? ? game['linescore'] : game['liveData']['linescore']

    inning = line_score.nil? ? 0 : line_score['currentInning']

    status = game['gameData'].nil? ? game['status'] : game['gameData']['status']

    if status['detailedState'] == 'Cancelled'
      return "Cancelled: #{status['reason']}"
    end

    if status['detailedState'].include? "Suspended"
      resume = game['resumeDate'] || game['gameDate'] || game['gameData']['datetime']['resumeDateTime']
      return "#{status['detailedState']}, will resume #{friendly_date resume, with_time: true, in_zone: "America/New_York"}"
    end

    if ['Final', 'Game Over'].include?(status['detailedState']) || status['detailedState'].start_with?('Completed Early')
      return inning == 9 ? "Final" : "Final/#{inning}"
    end

    if %w[Pre-Game Warmup Scheduled].include? status['detailedState']
      # get the start date in eastern time.
      time = game['gameDate'] || game['gameData']['datetime']['dateTime']
      starts = Time.parse(time).in_time_zone('Eastern Time (US & Canada)')
      return "#{status['detailedState']} (Starts: #{starts.strftime('%-l:%M %p %Z')})"
    end

    return status['detailedState'] if line_score.nil?

    inning_state = line_score['inningState']

    if inning_state.nil? || inning.nil?
      return "Unknown"
    end

    "#{inning_state} #{inning.ordinalize}"
  end

  # Checks to see if a pitch is in the strike zone.
  # If it's in the zone, it will return true.
  # If it's not in the zone, it will return how far away it is.
  # @return [Array<Boolean,String>] an array of if the ball is in the zone, and if not, how far away, or nil if it's irrelevant or incalculable
  def in_the_zone?(pitch_data)
    # 1-9 is always in the zone.
    return [true, nil] if pitch_data['zone'] and pitch_data['zone'] <= 9

    # Sometimes we don't have pitch coordinates.
    return [nil] if pitch_data['coordinates'].nil? or pitch_data['coordinates'].empty?

    # Check if the ball is out/in the zone based on Z-axis.
    z = pitch_data['coordinates']['pZ'] # ft
    x = pitch_data['coordinates']['pX'] # ft

    return [nil] if z.nil? or x.nil?

    # A baseball's diameter in inches is 1.43; convert it to feet add that to the height
    radius = 1.437 / 12.0 # convert to feet

    # Ball is above the zone
    if (z - radius) >= pitch_data['strikeZoneTop']
      return [false, "above by #{(((z - radius) - pitch_data['strikeZoneTop']) * 12).round(3)} in."]
    end
    # Ball is below the zone
    if (z + radius) <= pitch_data['strikeZoneBottom']
      return [false, "below by #{(((z + radius) - pitch_data['strikeZoneBottom']) * 12).round(3)} in."]
    end

    # Check if the ball is out/in the zone based on X-axis.
    strike_zone = 17/2 # inches
    strike_zone_in_feet = strike_zone / 12.0

    # Ball is to the right of the zone
    if (x - radius) >= strike_zone_in_feet
      return [false, "right by #{(((x - radius) - strike_zone_in_feet) * 12).round(3)} in."]
    end
    # Ball is to the left of the zone
    if (x + radius) <= -strike_zone_in_feet
      return [false, "left by #{-(((x + radius) + strike_zone_in_feet) * 12).round(3)} in."]
    end

    [true, nil] #"in"
  end

  # Returns if this ball was a bad umpire call.
  # If the umpire's call did not affect the result, such as a hit or a foul, it will return nil.
  def bad_call?(play_event)
    if play_event['details']['isBall']
      # Ignore if it's not a ball; we do not care about HBP that are considered balls.
      return nil unless play_event['details']['call']['description'].start_with? 'Ball'

      # If a ball is in the zone, it's a bad call.
      zone = in_the_zone?(play_event['pitchData'])

      zone.nil? ? nil : zone[0]
    elsif play_event['details']['isStrike']
      # Only care about called strikes.
      return nil unless play_event['details']['call']['description'] == "Called Strike"

      # If a strike is out of the zone, it's a bad call.
      zone = in_the_zone?(play_event['pitchData'])

      zone.nil? ? nil : !zone[0]
    else
      nil
    end
  end

  def homer_info(homer)
    description = homer['result']['description']

    if description.include? "call on the field"
      description = description.split("call on the field").last
    end

    homer_num = description.split(" (")[1].split(")")[0].to_i
    ball_info = description.split(")")[1].split(". ")[0]

    ball_info.gsub!("on a ", "")

    # Trim off leading or trailing spaces
    ball_info.strip!

    if homer['result']['rbi'] == 4
      ball_info = "Grand Slam #{ball_info}"
    end

    ball_info.capitalize!

    [homer_num, ball_info]
  end
end
