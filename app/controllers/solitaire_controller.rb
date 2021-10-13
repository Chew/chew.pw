class SolitaireController < ApplicationController
  def index
  end

  def challenges
    date = params['month'] + params['year'].split('')[2..4].join('')

    @info = Rails.cache.fetch("ms-solitaire-challenges-#{date}") do
      begin
        JSON.parse RestClient.get("https://download-ssl.msgamestudios.com/content/mgs/ce/production/SolitaireWin10/prod/MonthChallenges#{date}.js/1/MonthChallenges#{date}.js")
      rescue RestClient::NotFound
        flash[:modal_js] = "No challenge data found for this month!"
        return redirect_to "/solitaire/challenges/01/2015"
      end
    end
  end
end
