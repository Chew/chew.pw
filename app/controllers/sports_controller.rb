class SportsController < ApplicationController
  # @return [Nokogiri::HTML::Document]
  def retrieve_nfl_stats(year = 2021, season = "REG")
    data = Rails.cache.fetch('sports-nfl', expires_in: 1.day) do
      RestClient.get('https://www.nfl.com/standings/league/2021/REG', 'User-Agent': DUMMY_USER_AGENT).body
    end
    Nokogiri.parse(data)
  end

  def nfl
    stats = retrieve_nfl_stats

    # get the table tag
    table = stats.search('table')[0]

    if table.nil?
      render json: { error: "Could not find table" }
      return
    end

    # Get the headers from the table head
    headers = table.search('thead tr th').map { |e| e.text.strip }

    # Get the teams from the table body
    teams = table.search('tbody tr').map { |e| e.search('td').map {|f| f.text.strip } }

    @headers = headers
    @teams = teams
  end

  def nfl_api
    stats = retrieve_nfl_stats

    # get the table tag
    table = stats.search('table')[0]

    if table.nil?
      json_error_response("Could not find table")
      return
    end

    # Get the headers from the table head
    headers = table.search('thead tr th').map { |e| e.text.strip }

    # Get the teams from the table body
    teams = table.search('tbody tr').map { |e| e.search('td').map {|f| f.text.strip } }

    table = {}

    cur_team = ""
    teams.each do |team|
      team.each_with_index do |data, i|
        if i == 0
          # @type [Array<String>]
          name_data = data.split("\n")
          while name_data.last.strip.length <= 3
            name_data.pop
          end

          short = name_data.last.strip
          full_name = name_data.first
          cur_team = short
          table[short] = {}
          table[short]["name"] = full_name
          next
        end

        table[cur_team][headers[i]] = data
      end
    end

    json_response table
  end

  def mlb
    data = JSON.parse(RestClient.get('https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=2022&standingsTypes=regularSeason', 'User-Agent': DUMMY_USER_AGENT))

    @info = data['records']
  end

  def mlb_team
    @scores = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=1&hydrate=team(venue(timezone)),venue(timezone),game(seriesStatus,seriesSummary,seriesStatus,seriesSummary,linescore&season=2022&startDate=2022-04-08&endDate=2022-10-05&teamId=#{params[:team_id]}&eventTypes=primary&scheduleTypes=games,events,xref", 'User-Agent': DUMMY_USER_AGENT))

    @win_sum = []
    @team_name = ""
    @above500 = []
    @scores['dates'].each do |date|
      date['games'].each do |game|
        next unless game['status']['detailedState'] == 'Final'

        team = game['teams']['away']['team']['id'].to_i == params[:team_id].to_i ? 'away' : 'home'
        @team_name = game['teams'][team]['team']['name']
        @win_sum.push(game['teams'][team]['leagueRecord']['wins'] - game['teams'][team]['leagueRecord']['losses'])
        @above500.push game['teams'][team]['leagueRecord']['pct'].to_f
      end
    end
  end
end
