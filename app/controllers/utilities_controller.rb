class UtilitiesController < ApplicationController
  def vaccine
    @data = Rails.cache.fetch("vaccine/info", expires_in: 1.day) do
      # Get data from bloomberg
      res = RestClient.get("http://api.scraperapi.com?api_key=#{Rails.application.credentials.utilities[:scraper_api]}&url=https://www.bloomberg.com/graphics/covid-vaccine-tracker-global-distribution/")

      info = JSON.parse res.body.split('dvz-data-cave').last.split('dvz-content').first.split("\n")[1]

      {
        updated: Time.now,
        info: info
      }.as_json
    end
  end
end
