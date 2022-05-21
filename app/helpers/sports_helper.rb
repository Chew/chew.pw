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
end
