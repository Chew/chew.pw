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
    begin
      @team_info = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{params[:team_id]}?season=#{params[:season] || Time.now.year}&hydrate=team(roster(person(stats(seasonStats(splits(teamStats))))))", 'User-Agent': DUMMY_USER_AGENT))['teams'][0]
    rescue RestClient::NotFound
      # Render the sports layout with a "team not found" message
      return render html: "#{tag.h1("Team Not Found")}#{tag.p("Could not find the team you specified.")}#{link_to("View All Teams", "/sports/mlb/teams")}".html_safe,
             layout: 'application', status: 404
    end

    @scores = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=#{@team_info['sport']['id']}&season=#{params[:season] || Time.now.year}&teamId=#{params[:team_id]}&eventTypes=primary&scheduleTypes=games,events,xref&hydrate=flags", 'User-Agent': DUMMY_USER_AGENT))

    @win_sum = []
    @team = {
      "name" => @team_info['name'],
      "wins" => 0,
      "losses" => 0,
    }
    @above500 = []
    current_wins = 0
    @total_games = 0

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

        # Update the current wins and total games
        if game['teams'][team]['isWinner']
          current_wins += 1
          @team['wins'] += 1
        else
          current_wins -= 1
          @team['losses'] += 1
        end
        @total_games += 1

        # Store the win summary
        @win_sum.push current_wins
        @above500.push (current_wins / @total_games.to_f).round(3)
      end
    end

    @team['to500'] = current_wins
  end

  def mlb_game
    @game = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1.1/game/#{params[:game_id]}/feed/live", 'User-Agent': DUMMY_USER_AGENT))

    # Game does not exist
    if @game['gamePk'] == 0
      return render html: "#{tag.h1("Game Not Found")}#{tag.p("Could not find the game you specified.")}#{link_to("View Today's Schedule", "/sports/mlb/schedule")}".html_safe,
                  layout: 'application', status: 404
    end

    # Teams
    @away = @game['gameData']['teams']['away']
    @home = @game['gameData']['teams']['home']

    # Handle results for the pitching/batting cycle.
    @results = {}
    @results_by_pitcher = {}
    @results_by_batter = {}
    @results_by_inning = {}
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
      inning = "#{play['about']['halfInning'].capitalize} of the #{play['about']['inning'].ordinalize}"

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

      # Get batter plays
      @plays_by_batter[batter] ||= []
      @plays_by_batter[batter] << play

      # Get inning stats
      @results_by_inning[inning] ||= {}
      @results_by_inning[inning][event] ||= 0
      @results_by_inning[inning][event] += 1

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

    # Notable Events
    @notable = []

    # Check for no hitters or perfect game
    flags = @game['gameData']['flags']
    @notable.push("Perfect Game (#{flags['awayTeamPerfectGame'] ? @away['clubName'] : @home['clubName']})") if flags['perfectGame']
    @notable.push("No Hitter (#{flags['awayTeamNoHitter'] ? @away['clubName'] : @home['clubName']})") if flags['noHitter']

    # Check for batting the cycle
    @results_by_batter.each do |player, results|
      if results['Single'] and results['Double'] and results['Triple'] and results['Home Run']
        @notable.push("#{player} batted the cycle")
      end
    end

    # Check for immaculate innings (innings where there were 3 strikeouts, and nothing else)
    @results_by_inning.each do |inning, results|
      if results['Strikeout'] and results['Strikeout'] == 3 and results.values.sum == 3
        # Check to make sure there were only 9 pitches in the inning
        play_index = @game['liveData']['plays']['playsByInning'][inning.split(' ').last.to_i - 1][inning.split(' ').first.downcase]
        range = (play_index.first .. play_index.last)

        total_plays = 0

        @game['liveData']['plays']['allPlays'][range].each do |play|
          # Check pitchIndex to make sure it's 3 in length
          total_plays += play['pitchIndex'].length
        end

        @notable.push "#{inning} was an immaculate inning" if total_plays == 9
      end
    end

    away_score = @game['liveData']['linescore']['teams']['away']['runs'] || 0
    home_score = @game['liveData']['linescore']['teams']['home']['runs'] || 0

    winning = away_score > home_score ? @away['clubName'] : @home['clubName']
    losing = away_score > home_score ? @home['clubName'] : @away['clubName']

    @score = away_score > home_score ? "#{away_score} - #{home_score}" : "#{home_score} - #{away_score}"

    # Summary for meta description.
    # If the game is Final, use the final summary: "The winning team beat the losing time winning score to losing score."
    # If the game is in-progress, use the in-progress summary: "The winning team is beating the losing team winning score to losing score at the inning state inning ordinal."
    # If the game is scheduled, show when the game is scheduled: "The game is scheduled for date."
    if @game['gameData']['status']['abstractGameState'] == "Final"
      @summary = "The #{winning} beat the #{losing}, #{@score}."
    elsif @game['gameData']['status']['abstractGameState'] == "Live"
      # If the game is tied
      if away_score == home_score
        @summary = "The #{losing} are tied with the #{winning} at #{@score}."
      else
        linescore = @game['liveData']['linescore']
        @summary = "The #{winning} are leading the #{losing} #{@score} at the #{linescore['inningState']} of the #{linescore['currentInningOrdinal']}."
      end
    elsif @game['gameData']['status']['abstractGameState'] == "Preview"
      @summary = "The game is scheduled for #{Time.parse(@game['gameData']['datetime']['dateTime']).in_time_zone("Eastern Time (US & Canada)").strftime("%A, %B %d, %Y at %r %Z")}."
    end
  end

  def mlb_teams
    @teams = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams?season=#{params[:season] || Time.now.year}", 'User-Agent': DUMMY_USER_AGENT))['teams']

    # Sort the teams by either the parentOrgName (if it exists) or the name
    @teams.sort_by! do |team|
      if team['parentOrgName'].nil?
        team['name']
      else
        team['parentOrgName']
      end
    end

    # Major League Affiliate teams. Minor teams + rookie.
    @affiliates = ["Major League Baseball", "Triple-A", "Double-A", "High-A", "Single-A", "Rookie"]

    @sports = @teams.map {|e| e['sport']['name']}.uniq.sort_by do |item|
      if @affiliates.include? item
        @affiliates.index item
      else
        item[0].ord
      end
    end
  end

  def mlb_schedule
    date = params[:date] || Time.now.strftime("%m/%d/%Y")

    @schedule = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?language=en&sportId=1&date=#{date}&sortBy=gameDate&hydrate=game,linescore(runners),flags,team,review,alerts,homeRuns"))
  end
end
