class Games::SolitaireController < GamesController
  def index
  end

  def challenges_list
    @archive = Rails.cache.fetch("ms-solitaire-challenges-archive", expires_in: 1.day) do
      JSON.parse(RestClient.get("https://go.microsoft.com/fwlink/?linkid=2181471"))['categories'][0]['entries']
    end

    @months = @archive.map {|e| e['key']}
  end

  def challenges
    date = params['month'] + params['year'].split('')[2..4].join('')

    @archive = Rails.cache.fetch("ms-solitaire-challenges-archive", expires_in: 1.day) do
      JSON.parse(RestClient.get("https://go.microsoft.com/fwlink/?linkid=2181471"))['categories'][0]['entries']
    end

    @info = Rails.cache.fetch("ms-solitaire-challenges-#{date}", expires_in: 1.day) do
      # Find key
      name = nil
      @archive.each do |entry|
        # "key": "monthchallenges0119"
        next unless entry['key'] == "monthchallenges#{date}"

        name = entry['name']
      end

      if name
        JSON.parse RestClient.get("https://download-ssl.msgamestudios.com/content/mgs/ce/production/Solitaire/prod/dailychallenges/#{name}")
      else
        flash[:modal_js] = "No challenge data found for that month!"
        return redirect_to "/solitaire/challenges"
      end
    end
  end
end
