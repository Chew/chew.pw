class SportsController < ApplicationController
  before_action :sanitize_params

  def sanitize_params
    # Make sure season is a number, or, if it is not, set it to the current year
    params[:season] = params[:season].to_i if params[:season].is_a? String
    params[:season] = Time.now.year if params[:season].nil? || params[:season] == ""

    # Sane the season, has to be later than 1850 and earlier than current year + 1
    params[:season] = 1850 if params[:season] < 1850
    params[:season] = Time.now.year + 1 if params[:season] > Time.now.year + 1

    # Param to get the currently selected season
    @season = params[:season]
  end
end
