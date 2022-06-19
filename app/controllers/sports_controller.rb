class SportsController < ApplicationController
  include ActionView::Helpers::UrlHelper
  include SportsHelper

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
    @info = JSON.parse(RestClient.get('https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=2022&standingsTypes=regularSeason', 'User-Agent': DUMMY_USER_AGENT))['records']

    # Get today's date in Pacific Time (PDT) with MM/DD/YYYY format
    date = Time.now.in_time_zone("America/Los_Angeles").strftime("%m/%d/%Y")

    @schedule = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?language=en&sportId=1&date=#{date}&sortBy=gameDate&hydrate=game,linescore(runners),flags,team,review,alerts,homeRuns"))
  end

  def mlb_team
    @team_info = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{params[:team_id]}?season=#{params[:season] || Time.now.year}&hydrate=team(roster(person(stats(seasonStats(splits(teamStats))))))", 'User-Agent': DUMMY_USER_AGENT))['teams'][0]
    @scores = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=#{@team_info['sport']['id']}&season=#{params[:season] || Time.now.year}&teamId=#{params[:team_id]}&eventTypes=primary&scheduleTypes=games,events,xref", 'User-Agent': DUMMY_USER_AGENT))

    @win_sum = []
    @team = {
      "name" => "",
      "wins" => 0,
      "losses" => 0,
    }
    @above500 = []
    current_wins = 0
    total_games = 0

    # Iterate through all the days
    @scores['dates'].each do |date|
      # Iterate over the games that day (can be multiple)
      date['games'].each do |game|
        # We only care about completed games
        next unless ['Final', 'Completed Early', 'Game Over'].include? game['status']['detailedState']

        # We only care about regular season games
        next unless game['seriesDescription'] == 'Regular Season'

        # Get if we're home or away
        team = game['teams']['away']['team']['id'].to_i == params[:team_id].to_i ? 'away' : 'home'

        # Set the team name
        @team['name'] = game['teams'][team]['team']['name']

        # Update the current wins and total games
        if game['teams'][team]['isWinner']
          current_wins += 1
          @team['wins'] += 1
        else
          current_wins -= 1
          @team['losses'] += 1
        end
        total_games += 1

        # Store the win summary
        @win_sum.push current_wins
        @above500.push (current_wins / total_games.to_f).round(3)
      end
    end

    @team['to500'] = current_wins
  end

  def mlb_game
    @game = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1.1/game/#{params[:game_id]}/feed/live", 'User-Agent': DUMMY_USER_AGENT))

    # Teams
    @away = @game['gameData']['teams']['away']
    @home = @game['gameData']['teams']['home']

    # Handle results for the pitching/batting cycle.
    @results = {}
    @results_by_pitcher = {}
    @results_by_batter = {}
    @pitchers = []
    @batters = []
    @pitches = {}
    @pitches_by_pitcher = {}
    @pitches_by_batter = {}

    # Umpire blunder information
    @total_balls = 0
    @total_strikes = 0
    @blunder_balls = []
    @blunder_strikes = []
    @game['liveData']['plays']['allPlays'].each_with_index do |play, play_index|
      event = play['result']['event']
      pitcher = play['matchup']['pitcher']['fullName']
      batter = play['matchup']['batter']['fullName']

      # Add or set to 1 if it's a new pitch
      @results[event] ||= 0
      @results[event] += 1

      # Get pitcher stats
      @results_by_pitcher[pitcher] ||= {}
      @results_by_pitcher[pitcher][event] ||= 0
      @results_by_pitcher[pitcher][event] += 1

      # Get batter stats
      @results_by_batter[batter] ||= {}
      @results_by_batter[batter][event] ||= 0
      @results_by_batter[batter][event] += 1

      @pitches_by_pitcher[pitcher] ||= {}
      @pitches_by_batter[batter] ||= {}

      # Add to the pitcher and batter list
      @pitchers.push pitcher
      @batters.push batter

      # Iterate through the play events
      play['playEvents'].each do |play_event|
        # Ignore if it's not a pitch or pick-off
        if play_event['isPitch'] or play_event['type'] == 'pickoff'
          # Grab the kind
          kind = play_event['details']['description']

          # Update the pitching counts
          @pitches_by_pitcher[pitcher][kind] ||= 0
          @pitches_by_pitcher[pitcher][kind] += 1

          @pitches_by_batter[batter][kind] ||= 0
          @pitches_by_batter[batter][kind] += 1

          @pitches[kind] ||= 0
          @pitches[kind] += 1
        end

        # Check for blunders
        if play_event['isPitch'] and !play_event['pitchData'].nil?
          # Top/Bottom Inning - Pitcher to Batter - Pitch x
          play_description = "#{play['about']['halfInning'].capitalize} #{play['about']['inning'].ordinalize} - #{play['matchup']['pitcher']['fullName']} to #{play['matchup']['batter']['fullName']} - Pitch #{play_event['pitchNumber']}"

          if play_event['details']['isBall'] and play_event['details']['call']['description'] != "Hit By Pitch"
            @total_balls += 1
            if bad_call? play_event
              @blunder_balls.push(link_to(play_description, "#play-#{play_index}").html_safe)
            end
          elsif play_event['details']['isStrike'] and play_event['details']['call']['description'] == "Called Strike"
            @total_strikes += 1
            if bad_call? play_event
              @blunder_strikes.push(link_to(play_description, "#play-#{play_index}").html_safe)
            end
          end
        end
      end
    end

    # Make sure the pitchers are unique
    @pitchers = @pitchers.uniq
    @batters = @batters.uniq

    # Grab the inning info for future graph usage
    @inning_info = {
      'away' => [],
      'home' => [],
    }

    @game['liveData']['linescore']['innings'].each do |inning|
      %w[home away].each do |team|
        details = []
        inning[team].each do |_, value|
          details.push value
        end
        @inning_info[team].push details.join(',')
      end
    end

    # HP Umpire info
    umpire = @game['liveData']['boxscore']['officials'].find {|ump| ump['officialType'] == "Home Plate"}
    umpire.nil? ? @umpire = "Unknown" : @umpire = umpire['official']['fullName']

    # Player mapping
    @players = {}
    %w[home away].each do |team|
      @game['liveData']['boxscore']['teams'][team]['players'].each do |_, player_info|
        @players[player_info['person']['id']] = player_info['person']['fullName']
      end
    end
  end
end
