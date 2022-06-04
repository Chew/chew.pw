module SportsHelper
  def mlb_game_state(team_id, game)
    is_home = game['teams']['home']['team']['id'].to_i == team_id

    away_score = game['teams']['away']['score']
    home_score = game['teams']['home']['score']

    if ['Final', 'Completed Early', 'Game Over'].include? game['status']['detailedState']
      if is_home
        home_score > away_score ? "Win" : "Loss"
      else
        away_score > home_score ? "Win" : "Loss"
      end
    else
      "N/A"
    end
  end

  # Total innings for a game
  def total_innings(line_score)
    line_score['scheduledInnings'] > line_score['currentInning'] ? line_score['scheduledInnings'] : line_score['currentInning']
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

  # Finds the game status for a given game
  def game_status(game)
    line_score = game['liveData'].nil? ? game['linescore'] : game['liveData']['linescore']

    inning = line_score.nil? ? 0 : line_score['currentInning']

    status = game['gameData'].nil? ? game['status'] : game['gameData']['status']

    if ['Final', 'Completed Early', 'Game Over'].include? status['detailedState']
      return inning == 9 ? "Final" : "Final/#{inning}"
    end

    if %w[Pre-Game Warmup Scheduled].include? status['detailedState']
      # get the start date in eastern time.
      time = game['gameDate'] || game['gameData']['datetime']['dateTime']
      starts = Time.parse(time).in_time_zone('Eastern Time (US & Canada)')
      return "#{status['detailedState']} (Starts: #{starts.strftime('%-l:%M %p')} ET)"
    end

    return status['detailedState'] if line_score.nil?

    inning_state = line_score['inningState']

    "#{inning_state} #{inning.ordinalize}"
  end

  # Checks to see if a pitch is in the strike zone.
  def in_the_zone?(pitch_data)
    # 1-9 is always in the zone.
    return true if pitch_data['zone'] and pitch_data['zone'] <= 9

    # Sometimes we don't have pitch coordinates.
    return nil if pitch_data['coordinates'].nil? or pitch_data['coordinates'].empty?

    # Check if the ball is out/in the zone based on Z-axis.
    z = pitch_data['coordinates']['pZ'] # ft
    x = pitch_data['coordinates']['pX'] # ft

    # A baseball's diameter in inches is 1.43; convert it to feet add that to the height
    radius = 1.437 / 12.0 # convert to feet

    # Ball is above the zone
    if (z - radius) >= pitch_data['strikeZoneTop']
      return false #"above by #{z - pitch_data['strikeZoneTop']} ft"
    end
    # Ball is below the zone
    if (z + radius) <= pitch_data['strikeZoneBottom']
      return false #"below by #{(z - pitch_data['strikeZoneBottom']).round(2)} ft"
    end

    # Check if the ball is out/in the zone based on X-axis.
    strike_zone = 17/2 # inches
    strike_zone_in_feet = strike_zone / 12.0

    # Ball is to the right of the zone
    if (x - radius) >= strike_zone_in_feet
      return false #"right by #{(x + radius - strike_zone_in_feet).round(2)} feet"
    end
    # Ball is to the left of the zone
    if (x + radius) <= -strike_zone_in_feet
      return false # "left by #{(x - radius + strike_zone_in_feet).round(2)} feet"
    end

    true #"in"
  end
end
