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
end
