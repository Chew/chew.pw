module SportsHelper
  def mlb_game_state(team_id, game)
    is_home = game['teams']['away']['team']['id'].to_i == team_id

    if ['Final', 'Completed Early'].include? game['status']['detailedState']
      is_home && game['teams']['home']['score'].to_i > game['teams']['away']['score'].to_i ? 'Win' : 'Loss'
    else
      "Unknown"
    end
  end
end
