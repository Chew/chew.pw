class SportsController < ApplicationController
  before_action :sanitize_params

  def sanitize_params
    # Make sure season is a number, or, if it is not, set it to the current year
    params[:season] = params[:season].to_i if params[:season].is_a? String
    params[:season] = Time.now.year if params[:season].nil? || params[:season] == ""

    # Sane the season, has to be later than 1850 and earlier than current year + 1
    params[:season] = 1850 if params[:season] < 1850
    params[:season] = Time.now.year + 1 if params[:season] > Time.now.year + 1

    # Subtract a year depending on the sport and month
    sport = request.path.split('/')[2] # /sports/mlb <- that

    case sport
    when 'mlb'
      # Don't need to subtract a year, baseball is reasonable and the entire season is within one year
    when 'nfl'
      # Subtract a year if it's before August
      params[:season] -= 1 if Time.now.month < 8
    when 'nhl'
      # Subtract a year if it's before September
      params[:season] -= 1 if Time.now.month < 9
    else
      # Unimplemented sport, just set it to the current year
    end

    # Param to get the currently selected season
    @season = params[:season]

    # Clean game id just in case
    params[:game_id] = params[:game_id].to_i if params[:game_id].is_a? String
  end
end
