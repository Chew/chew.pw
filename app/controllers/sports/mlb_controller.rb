class Sports::MlbController < SportsController
  include ActionView::Helpers::UrlHelper
  include SportsHelper
  include ApplicationHelper

  # We need to get the team name and cache it if we're on a team page
  before_action :team_name
  def team_name
    # Check if we're on a team page, e.g. /sports/mlb/team/:id
    return unless request.path.start_with?('/sports/mlb/team/')
    teamId = params[:team_id]

    @team_name = Rails.cache.fetch("mlb-team-#{teamId}-season-#{@season}", expires_in: 1.month) do
      begin
        j = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{teamId}?season=#{@season}&fields=teams,name"))

        j['teams'][0]['name']
      rescue RestClient::NotFound
        next nil
      end
    end
  end

  def mlb
    @info = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=#{params[:season] || Time.now.year}&standingsTypes=regularSeason&hydrate=division", 'User-Agent': DUMMY_USER_AGENT))['records']
    teams = {}
    @info.each do |division|
      division['teamRecords'].each do |team|
        teams[team['team']['id']] = team['team']['name']
      end
    end

    # Get today's date in Pacific Time (PDT) with MM/DD/YYYY format
    today = Time.now.in_time_zone("America/Los_Angeles")
    date = today.strftime("%m/%d/%Y")

    @schedule = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?language=en&sportId=1&date=#{date}&sortBy=gameDate&hydrate=game,linescore(runners),flags,team,review,alerts,homeRuns"))
    people = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/sports/1/players?season=#{params[:season] || Time.now.year}&gameType=R&fields=people,fullName,birthDate,currentTeam,id,primaryPosition,name,currentAge", 'User-Agent': DUMMY_USER_AGENT))['people']
    @birthdays = []
    people.delete_if do |person|
      next true if person['birthDate'].nil?
      birthday = Date.parse(person['birthDate'])

      not birthday.month == today.month && birthday.day == today.day
    end
    people.each do |person|
      @birthdays.push "#{person['fullName']} (#{person['currentAge']}) [#{person['primaryPosition']['name']} for #{teams[person['currentTeam']['id']]}]"
    end
  end

  def mlb_team
    begin
      @team_info = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{params[:team_id]}?season=#{params[:season] || Time.now.year}&hydrate=standings,team(roster(person(stats(seasonStats(splits(teamStats))))))", 'User-Agent': DUMMY_USER_AGENT))['teams'][0]
    rescue RestClient::NotFound
      # Render the sports layout with a "team not found" message
      return render status: 404, action: 'error', layout: 'application', locals: {
        message: "Team Not Found", description: "Could not find the team you specified.",
        href: "/sports/mlb/teams", link_text: "View All Teams"
      }
    end

    @scores = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=#{@team_info['sport']['id']}&season=#{params[:season] || Time.now.year}&teamId=#{params[:team_id]}&eventTypes=primary&scheduleTypes=games,events,xref&hydrate=flags,linescore", 'User-Agent': DUMMY_USER_AGENT))

    @win_sum = []
    @team = {
      "name" => @team_info['name'],
      "wins" => 0,
      "losses" => 0,
    }
    @above500 = []
    cur_diff = 0
    @run_diff = []
    current_wins = 0
    @total_games = 0
    @run_game_records = {}
    @team_game_records = {}

    @home_scores_first = [0, 0]
    @opponent_scores_first = [0, 0]
    @bonus_records = {
      "#{@team_info['clubName']} Scores First" => [0, 0],
      "Opponent Scores First" => [0, 0],
    }
    %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].each do |day|
      @bonus_records[day] = [0, 0]
    end

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
        opponent_side = team == 'away' ? 'home' : 'away'
        opponent = game['teams'][opponent_side]['team']['name']

        # Get the scores
        our_score = game['teams'][team]['score']
        their_score = game['teams'][opponent_side]['score']
        home_score = game['teams']['home']['score']
        away_score = game['teams']['away']['score']
        diff = (home_score - away_score).abs

        # Other info
        day_of_week = Time.parse(date['date']).strftime("%A")

        # Iterate through line-score to see who scored first (home or away)
        scored_first = nil
        (game.dig('linescore', 'innings') || []).each do |inning|
          next unless scored_first.nil?
          %w[away home].each do |side|
            next unless scored_first.nil?

            scored_first = side if inning[side]['runs'].to_i > 0
          end
        end

        # Make sure the differential exists for this, array is wins, losses.
        @run_game_records[diff] ||= [0, 0]
        @team_game_records[opponent] ||= [0, 0]

        # Update run differential
        cur_diff += our_score - their_score
        @run_diff.push cur_diff

        # Update the current wins and total games
        if game['teams'][team]['isWinner']
          current_wins += 1
          @run_game_records[diff][0] += 1
          @team_game_records[opponent][0] += 1
          @team['wins'] += 1
          scored_first == opponent_side ? @bonus_records["Opponent Scores First"][0] += 1 : @bonus_records["#{@team_info['clubName']} Scores First"][0] += 1
          @bonus_records[day_of_week][0] += 1
        else
          current_wins -= 1
          @run_game_records[diff][1] += 1
          @team_game_records[opponent][1] += 1
          @team['losses'] += 1
          scored_first == opponent_side ? @bonus_records["Opponent Scores First"][1] += 1 : @bonus_records["#{@team_info['clubName']} Scores First"][1] += 1
          @bonus_records[day_of_week][1] += 1
        end
        @total_games += 1

        # Store the win summary
        @win_sum.push current_wins
        @above500.push (current_wins / @total_games.to_f).round(3)
      end
    end

    @team['to500'] = current_wins
  end

  def team_homers
    @data = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?lang=en&sportId=1&season=#{@season}&teamId=#{params[:team_id]}&hydrate=homeRuns"))['dates']

    # Now to get the homers!
    @homers = []
    # Map of game type to player names to counts
    # e.g. { "Regular Season" => { "Mike Trout" => 3 } }
    @counts = {}
    @team = ""
    @data.each do |date|
      date['games'].each do |game|
        next if game['homeRuns'].nil? or game['homeRuns'].empty?

        # Get if we're home or away
        team = game['teams']['away']['team']['id'].to_i == params[:team_id].to_i ? 'away' : 'home'
        opponent_side = team == 'away' ? 'home' : 'away'
        opponent_inning = team == 'away' ? 'bottom' : 'top'
        opponent = game['teams'][opponent_side]['team']['name']

        @team = game['teams'][team]['team']['name']

        game['homeRuns'].each do |homer|
          top_or_bottom = homer['about']['halfInning'] # will be top or bottom
          # skip if it's not the team we're looking for
          next if opponent_inning == top_or_bottom

          # vars
          name = homer['matchup']['batter']['fullName']
          type = game['seriesDescription']

          # Update the counts
          @counts[type] ||= {}
          @counts[type][name] ||= 0
          @counts[type][name] += 1

          # Find if it's @ or vs (away or home)
          key = team == 'away' ? '@' : 'vs'

          @homers.push({
            "name" => homer['matchup']['batter']['fullName'],
            "count" => @counts[type][name],
            "opponent" => "#{key} #{opponent}",
            "rbi" => homer['result']['rbi'],
            "game_id" => game['gamePk'],
            "game_type" => game['seriesDescription'],
            "date" => game['gameDate'],
          })
        end
      end
    end
  end

  def mlb_draft
    @draft = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/draft/#{params[:year]}", 'User-Agent': DUMMY_USER_AGENT))

    @teams = {}
    @players = {}
    @positions = {}
    @states = {}
    @draft['drafts']['rounds'].each do |round|
      round['picks'].each do |pick|
        next if pick['person'].nil?

        name = pick['person']['fullName']
        team = pick['team']
        position_name = pick['person']['primaryPosition']['name']
        state = "#{pick['home']['state']}, #{pick['home']['country']}"

        @players[name] = pick['pickNumber']

        @teams[team] ||= []
        @teams[team].push pick

        @positions[position_name] ||= 0
        @positions[position_name] += 1

        @states[state] ||= 0
        @states[state] += 1
      end
    end
  end

  def mlb_game
    begin
      @game = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1.1/game/#{params[:game_id]}/feed/live", 'User-Agent': DUMMY_USER_AGENT))
    rescue RestClient::NotFound
      # Render the sports layout with a "game not found" message
      return render status: 404, action: 'error', layout: 'application', locals: {
        message: "Game Not Found", description: "Could not find the game you specified (404).",
        href: "/sports/mlb/schedule", link_text: "View All Games"
      }
    rescue RestClient::InternalServerError, RestClient::BadGateway
      # Render the sports layout with a "could not load game" message
      return render status: 200, action: 'error', layout: 'application', locals: {
        message: "Could Not Load Game", description: "There was an error loading the specified game on MLB's end. Please reload and try again.",
        href: "/sports/mlb/schedule", link_text: "View All Games"
      }
    end

    # Game does not exist
    if @game['gamePk'] == 0
      return render status: 404, action: 'error', layout: 'application', locals: {
        message: "Game Not Found", description: "Could not find the game you specified.",
        href: "/sports/mlb/schedule", link_text: "View All Games"
      }
    end

    # Win Percentage
    @win = {}
    begin
      @win_probability = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/game/#{params[:game_id]}/winProbability?language=en&fields=atBatIndex,homeTeamWinProbability,awayTeamWinProbability,homeTeamWinProbabilityAdded", 'User-Agent': DUMMY_USER_AGENT))

      @win_probability.each do |prob|
        @win[prob['atBatIndex']] = prob
      end
    rescue RestClient::NotFound, RestClient::InternalServerError, RestClient::BadGateway
      # We don't care if this fails, a refresh fixes it anyway.
    end

    # Teams
    @away = @game['gameData']['teams']['away']
    @home = @game['gameData']['teams']['home']

    # Handle results for the pitching/batting cycle.
    @results = {}
    @results_by_pitcher = {}
    @results_by_batter = {}
    @plays_by_batter = {}
    @results_by_inning = {}
    @pitchers = []
    @batters = []
    @pitches = {}
    @pitches_by_pitcher = {}
    @pitches_by_batter = {}

    # Total outs so far this game. Usually, max is 54.
    @outs = 0
    @max_outs = 54
    # Average duration of plays
    @plays = @game['liveData']['plays']['allPlays'].length
    @duration = 0

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

      if play['about']['inning'] > 9
        @max_outs = 6 * (play['about']['inning'])
      end
      if play['about']['hasOut']
        @outs += 1
        # add one for double plays, two for triple plays
        @outs += 1 if play['result']['eventType'].include?("double_play")
        @outs += 2 if play['result']['eventType'].include?("triple_play")
      end
      now = Time.now.to_s
      @duration += Time.parse(play.dig('about', 'endTime') || now).to_f - Time.parse(play.dig('about', 'startTime') || now).to_f

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
              @blunder_balls.push([play_description, play_index])
            end
          elsif play_event['details']['isStrike'] and play_event['details']['call']['description'] == "Called Strike"
            @total_strikes += 1
            if bad_call? play_event
              @blunder_strikes.push([play_description, play_index])
            end
          end
        end
      end
    end

    if @plays > 0
      remaining_half_innings = ((@max_outs - @outs) / 3.0).ceil
      average_duration_per_play = @duration / @plays.to_f
      remaining_duration = average_duration_per_play * (remaining_half_innings * 6)
      additional_time_per_half_inning = 120 # 2 minutes in seconds

      @estimated_done = Time.now.in_time_zone(@game['gameData']['venue']['timeZone']['id']) + remaining_duration + (additional_time_per_half_inning * remaining_half_innings)
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
        @players[player_info['person']['id']] = {
          "name" => player_info['person']['fullName'],
          "stats" => player_info,
          "info" => @game['gameData']['players']["ID#{player_info['person']['id']}"],
        }
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

    @boxscore = boxscore(@game)
    @boxscore_info = {
      "Batters" => %w[AB R H RBI BB K AVG OPS],
      "Pitchers" => %w[IP H R ER BB K HR ERA],
      "Bench" => %w[B Pos AVG G R H HR RBI SB],
      "Bullpen" => %w[T ERA IP H BB K]
    }

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

  def boxscore(data)
    # box score info,  mostly has everything
    box = data['liveData']['boxscore']
    # complete player data
    players = data['gameData']['players']
    teams = data['gameData']['teams']

    # final render
    boxscore = {
      "teams" => {},
      "info" => ""
    }

    %w[away home].each do |tea|
      team_info = teams[tea]
      box_team = box['teams'][tea]

      box_batters = []
      box_pitchers = []
      box_bench = []
      box_bullpen = []

      # handle batters
      box_team['batters'].each do |batter|
        player_stats = box_team['players']["ID#{batter}"]
        player_batting_stats = player_stats['stats']['batting']
        player_info = players["ID#{batter}"]

        next if player_batting_stats.empty?

        batter_box = {
          "name" => player_info['boxscoreName'],
          "position" => player_stats['allPositions'].map{|e| e['abbreviation']}.join('-'),
          "note" => player_batting_stats['note'],
          "stats" => {
            "ab" => player_batting_stats['atBats'],
            "r" => player_batting_stats['runs'],
            "h" => player_batting_stats['hits'],
            "rbi" => player_batting_stats['rbi'],
            "bb" => player_batting_stats['baseOnBalls'],
            "k" => player_batting_stats['strikeOuts'],
            "avg" => player_stats['seasonStats']['batting']['avg'],
            "ops" => player_stats['seasonStats']['batting']['ops'],
          }
        }

        box_batters << batter_box
      end
      batting_team_stats = box_team['teamStats']['batting']
      batting_totals = {
        "name" => "Totals",
        "stats" => {
          "ab" => batting_team_stats['atBats'],
          "r" => batting_team_stats['runs'],
          "h" => batting_team_stats['hits'],
          "rbi" => batting_team_stats['rbi'],
          "bb" => batting_team_stats['baseOnBalls'],
          "k" => batting_team_stats['strikeOuts'],
        }
      }
      box_batters << batting_totals

      # handle pitchers
      box_team['pitchers'].each do |pitcher|
        player_stats = box_team['players']["ID#{pitcher}"]
        player_pitching_stats = player_stats['stats']['pitching']
        player_info = players["ID#{pitcher}"]

        pitcher_box = {
          "name" => player_info['boxscoreName'],
          "note" => player_pitching_stats['note'],
          "stats" => {
            "ip" => player_pitching_stats['inningsPitched'],
            "h" => player_pitching_stats['hits'],
            "r" => player_pitching_stats['runs'],
            "er" => player_pitching_stats['earnedRuns'],
            "bb" => player_pitching_stats['baseOnBalls'],
            "k" => player_pitching_stats['strikeOuts'],
            "hr" => player_pitching_stats['homeRuns'],
            "era" => player_stats['seasonStats']['pitching']['era']
          }
        }

        box_pitchers << pitcher_box
      end
      pitching_team_stats = box_team['teamStats']['pitching']
      pitching_totals = {
        "name" => "Totals",
        "stats" => {
          "ip" => pitching_team_stats['inningsPitched'],
          "h" => pitching_team_stats['hits'],
          "r" => pitching_team_stats['runs'],
          "er" => pitching_team_stats['earnedRuns'],
          "bb" => pitching_team_stats['baseOnBalls'],
          "k" => pitching_team_stats['strikeOuts'],
          "hr" => pitching_team_stats['homeRuns']
        }
      }
      box_pitchers << pitching_totals

      # handle bench
      box_team['bench'].each do |bench|
        player_stats = box_team['players']["ID#{bench}"]
        player_batting_stats = player_stats['seasonStats']['batting']
        player_info = players["ID#{bench}"]

        next if player_batting_stats.empty?

        bench_box = {
          "name" => player_info['boxscoreName'],
          "stats" => {
            "b" => player_info.dig('batSide', 'code') || 'X',
            "pos" => player_info['primaryPosition']['abbreviation'],
            "avg" => player_batting_stats['avg'],
            "g" => player_batting_stats['gamesPlayed'],
            "r" => player_batting_stats['runs'],
            "h" => player_batting_stats['hits'],
            "hr" => player_batting_stats['homeRuns'],
            "rbi" => player_batting_stats['rbi'],
            "sb" => player_batting_stats['stolenBases'],
          }
        }

        box_bench << bench_box
      end

      # handle bullpen
      box_team['bullpen'].each do |bullpen|
        player_stats = box_team['players']["ID#{bullpen}"]
        player_pitching_stats = player_stats['seasonStats']['pitching']
        player_info = players["ID#{bullpen}"]

        bullpen_box = {
          "name" => player_info['boxscoreName'],
          "stats" => {
            "t" => player_info.dig('pitchHand', 'code') || 'X',
            "era" => player_pitching_stats['era'],
            "ip" => player_pitching_stats['inningsPitched'],
            "h" => player_pitching_stats['hits'],
            "bb" => player_pitching_stats['baseOnBalls'],
            "k" => player_pitching_stats['strikeOuts']
          }
        }

        box_bullpen << bullpen_box
      end

      # add data to the boxscore
      boxscore['teams'][tea] = {
        "team" => {
          "id" => team_info['id'],
          "name" => team_info['name'],
          "abbreviation" => team_info['abbreviation'],
        },
        "batters" => box_batters,
        "pitchers" => box_pitchers,
        "bench" => box_bench,
        "bullpen" => box_bullpen,
        "info" => {
          "batting" => box_team['info'].detect{|e| e['title'] == "BATTING"}&.dig('fieldList'),
          "baserunning" => box_team['info'].detect{|e| e['title'] == "BASERUNNING"}&.dig('fieldList'),
          "fielding" => box_team['info'].detect{|e| e['title'] == "FIELDING"}&.dig('fieldList'),
          "notes" => box_team['note'],
        }
      }
    end

    boxscore['info'] = box['info']

    boxscore
  end

  def game_pace
    @game_pace = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/gamePace?season=#{@season}&sportId=1&hydrate=sport"))['sports'][0]
    # This tells the frontend season dropdown to show 1999 to now
    @team_info = {
      "firstYearOfPlay" => 1999
    }
  end

  # Home Run Derby
  def mlb_derby
    begin
      @game = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/homeRunDerby/#{params[:game_id]}", 'User-Agent': DUMMY_USER_AGENT))
    rescue RestClient::NotFound
      return render status: 404, action: 'error', layout: 'application', locals: {
        message: "Game Not Found", description: "Could not find the game you specified.",
        href: "/sports/mlb", link_text: "Back Home"
      }
    end

    @top = {}
    @homers = {}
    @game['rounds'].each do |round|
      round['matchups'].each do |matchup|
        %w[topSeed bottomSeed].each do |seed|
          info = matchup[seed]
          hits = info['hits'] || []
          @top["#{info['player']['fullName']} - #{hits.count {|e| e['homeRun']}} (Round #{round['round']})"] = hits.count {|e| e['homeRun']}

          @homers[info['player']['fullName']] ||= 0
          @homers[info['player']['fullName']] += hits.count {|e| e['homeRun']}
        end
      end
    end
  end

  def mlb_teams
    @teams = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams?season=#{params[:season] || Time.now.year}", 'User-Agent': DUMMY_USER_AGENT))['teams']

    # Sort the teams by either the parentOrgName (if it exists) or the name
    @teams.sort_by! do |team|
      if team['parentOrgName'].nil?
        team['name'].nil? ? "#{team['id']}" : team['name']
      else
        team['parentOrgName']
      end
    end

    # Major League Affiliate teams. Minor teams + rookie.
    @affiliates = ["Major League Baseball", "Triple-A", "Double-A", "High-A", "Single-A", "Rookie"]

    @sports = @teams.map {|e| e['sport'].nil? ? "Unknown" : e['sport']['name']}.uniq.sort_by do |item|
      if @affiliates.include? item
        @affiliates.index item
      else
        item[0].ord
      end
    end
  end

  def mlb_team_stats
    team = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{params[:team_id]}?fields=teams,name,sport,id", 'User-Agent': DUMMY_USER_AGENT))['teams'][0]
    @team_name = team['name']
    begin
      @stats = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/teams/#{params[:team_id]}/stats?sportId=#{team['sport']['id']}&season=#{params[:season]}&stats=season&group=hitting,pitching,fielding,catching,running&gameType=R"))['stats']
    rescue RestClient::NotFound
      return render status: 404, action: 'error', layout: 'application', locals: {
        message: "Team Not Found", description: "Could not find the team you specified, or there are no statistics available.",
        href: "/sports/mlb/teams", link_text: "View All Teams"
      }
    end
  end

  def mlb_team_affiliates
    url = "https://statsapi.mlb.com/api/v1/teams/affiliates?teamIds=#{params[:team_id]}&hydrate=nextSchedule,previousSchedule,standings&season=#{@season}"
    sports = ["Major League Baseball", "Triple-A", "Double-A", "High-A", "Single-A", "Rookie"]

    @affiliates = JSON.parse(RestClient.get(url, 'User-Agent': DUMMY_USER_AGENT))['teams'].sort_by do |team|
      if sports.include? team['sport']['name']
        sports.index team['sport']['name']
      else
        team['sport']['name'][0].ord
      end
    end

    @major_league_team = @affiliates.find {|e| e['sport']['name'] == "Major League Baseball"}&.dig('name') || @affiliates[0]['name']

    today = Time.now.in_time_zone("America/Los_Angeles")

    games = []
    @affiliates.each do |affiliate|
      (affiliate['previousGameSchedule']['dates'] + affiliate['nextGameSchedule']['dates']).each do |date|
        next unless today.strftime("%Y-%m-%d") == date['date']
        date['games'].each do |game|
          games.push game['gamePk']
        end
      end
    end

    games = games.uniq

    if games.empty?
      @schedule = {
        "dates" => []
      }
      @games = []
    else
      @schedule = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?language=en&hydrate=game,linescore,flags,team,review,alerts,homeRuns&gamePks=#{games.join(',')}", 'User-Agent': DUMMY_USER_AGENT))
      @all_games = @schedule['dates'].reject {|e| e['date'] != today.strftime("%Y-%m-%d")}.first['games']
      @games = @all_games.sort_by do |game|
        if sports.include? game['teams']['home']['team']['sport']['name']
          sports.index game['teams']['home']['team']['sport']['name']
        else
          game['teams']['home']['team']['sport']['name'].ord
        end
      end
    end
  end

  def mlb_schedule
    date = params[:date] || Time.now.strftime("%m/%d/%Y")

    @sports = Rails.cache.fetch(:mlb_sports, expires_in: 1.hour) do
      JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/sports?season=#{params[:season] || Time.now.year}", 'User-Agent': DUMMY_USER_AGENT))['sports']
    end
    @schedule = JSON.parse(RestClient.get("https://statsapi.mlb.com/api/v1/schedule?language=en&sportId=#{params[:sport] || 1}&date=#{date}&sortBy=gameDate&hydrate=game,linescore(runners),flags,team,review,alerts,homeRuns"))
  end

  RESULT_RANGES = {
    "Single" => (0.00000..0.13705), 
    "Double" => (0.13705..0.18014),
    "Triple" => (0.18014..0.18382),
    "Homer" => (0.18382..0.21640),
    "Walks" => (0.21640..0.30296),
    "Strikeout" => (0.30296..0.53394),
    "Double Play" => (0.53394..0.55218),
    "Hit By Pitch" => (0.55218..0.56376),
    "Sac Hit" => (0.56376..0.56796),
    "Sac Fly" => (0.56796..0.57422),
    "Intent Walk" => (0.57422..0.57808),
    "Misc Out" => (0.57808..1.00000)
  }

  POSITIONS = [
    "first-baseman", "second-baseman", "shortstop", "third-baseman", "catcher", "left field", "center field", "right field", "pitcher"
  ]

  # Generates a never-before seen game of baseball!
  def mlb_game_generator
    # Generate 18 random names
    @away = Faker::Team.name
    @home = Faker::Team.name

    @away_players = []
    @home_players = []

    9.times do
      @away_players.push "#{Faker::Name.male_first_name} #{Faker::Name.last_name}"
    end

    9.times do
      @home_players.push "#{Faker::Name.male_first_name} #{Faker::Name.last_name}"
    end

    @outs = 0
    @bases = 0
    @base = [nil, nil, nil]
    @innings = {
      @away => [],
      @home => []
    }
    @line_score = {
      @away => [0,0,0,0,0,0,0,0,0],
      @home => [0,0,0,0,0,0,0,0,0]
    }
    @runs = 0

    @results = []
    current_inning = []
    inning_outs = 0
    inning = 0
    play = {
      @away => 0,
      @home => 0
    }
    top_half = true
    game_over = false
    until game_over
      # Make sure we have data
      @line_score[top_half ? @away : @home][inning] ||= 0

      # Generate a random number
      random = rand

      # Find the range of the random number
      RESULT_RANGES.each do |result, range|
        if range.include? random
          @result = result
          break
        end
      end

      play[top_half ? @away : @home] += 1
      current_play = play[top_half ? @away : @home]
      player = top_half ? @away_players[current_play % 9] : @home_players[current_play % 9]
      description = nil
      advances = nil

      pitches = nil

      ball_type = ["line drive", "fly ball"].sample
      field = %w[left center right].sample

      if @result == "Double Play" and (@base.count(nil) == 3 || (@outs % 3) == 2)
        @result = "Misc Out"
      end

      outs = 0
      case @result
      when "Single"
        description = "#{player} singles on a #{ball_type} to #{field} field."
        advances = advance_runners @base, 1, player
        pitches = random_at_bat true, false, false, false
      when "Double"
        description = "#{player} doubles on a #{ball_type} to #{field} field."
        advances = advance_runners @base, 2, player
        pitches = random_at_bat true, false, false, false
      when "Triple"
        description = "#{player} triples on a #{ball_type} to #{field} field."
        advances = advance_runners @base, 3, player
        pitches = random_at_bat true, false, false, false
      when "Homer"
        advances = advance_runners @base, 4, player
        description = "#{player} #{advances[1].count == 4 ? "hits a grand slam" : "homers on a #{ball_type}"} to #{field} field."
        pitches = random_at_bat true, false, false, false, "run(s)"
      when "Walks"
        description = "#{player} walks."
        advances = advance_runners @base, 1, player
        pitches = random_at_bat false, false, true, false
      when "Intent Walk"
        pitcher = top_half ? @home_players : @away_players
        description = "#{pitcher.last} intentionally walks #{player}."
        advances = advance_runners @base, 1, player
        pitches = ["Automatic Ball"] * 4
      when "Hit By Pitch"
        description = "#{player} hit by pitch."
        advances = advance_runners @base, 1, player
        pitches = random_at_bat false, false, false, true
      when "Double Play"
        if @outs % 3 == 2
          outs = 1
        else
          outs = 2
        end
        pitches = random_at_bat true, false, false, false, "out(s)"
        description = "#{player} grounds into a double play."
      when "Sac Hit", "Sac Fly"
        outs += 1
        description = "#{player} out on a #{@result.downcase} to #{field} field."
        advances = advance_runners @base, 1, player
        pitches = random_at_bat true, false, false, false, "out(s)"
      when "Strikeout"
        outs += 1
        pitches = random_at_bat false, true, false, false
        out_type = pitches.last.include?("Called") ? "called out on strikes" : "struck out swinging"
        description = "#{player} #{out_type}."
      when "Misc Out"
        @result = %w[Line-out Groundout Force-out Fly-out Pop-out].sample
        outs += 1
        catch = top_half ? @home_players : @away_players
        case @result
        when "Line-out", "Fly-out", "Pop-out"
          description = "#{player} #{@result.downcase.split('-').join('s ')} to #{field} fielder #{catch[%w[left center right].index(field) + 5]}."
        when "Groundout"
          out_to = POSITIONS[0..3].sample
          if out_to == "first-baseman"
            description = "#{player} grounds out to first-baseman #{catch[0]}."
          else
            description = "#{player} grounds out, #{out_to} #{catch[POSITIONS.index(out_to)]} to first-baseman #{catch[0]}."
          end
        when "Force-out"
          description = "#{player} is forced-out."
        end
        pitches = random_at_bat true, false, false, false, "out(s)"
      else
        raise "Unknown result: #{@result}"
      end

      @outs += outs
      @results.push([@result, @outs])
      inning_outs += outs
      current_inning << [description, @result, inning_outs, @base.dup, pitches, current_play]
      # New inning
      if inning_outs == 3
        # Check for game over

        # If 9th inning, top half, check to see home team has more points.
        if inning == 8 && top_half && @line_score[@home].sum > @line_score[@away].sum
          @innings[@home].push []
          #@line_score[@home][inning] = "-"
          game_over = true
        end

        # Check to see if we need to go extra innings. If the scores are the same, continue, else, game over.
        if inning == 8 && !top_half && @line_score[@home].sum != @line_score[@away].sum
          game_over = true
        end

        # If past 9th inning, we must always have a winner.
        if inning > 8 and @line_score[@home].sum != @line_score[@away].sum and !top_half
          game_over = true
        end

        @innings[top_half ? @away : @home].push current_inning
        current_inning = []
        @base = [nil, nil, nil]
        inning_outs = 0
        unless top_half
          inning += 1
        end
        top_half = !top_half
      else
        # Advance runners, if any
        next if advances.nil?

        @base = advances[0]
        unless advances[1].empty?
          @line_score[top_half ? @away : @home][inning] += advances[1].length
          scores = advances[1].map { |e| "#{e} scores." }
          # Remove the last item in the current_inning array since we need to change it
          current_inning.pop
          pitches.pop
          pitches.push "In play, run(s)"
          current_inning << ["#{description} #{scores.join(' ')}", @result, inning_outs, @base.dup, pitches, current_play]
        end
      end
    end
  end

  # Advance the runners. Returns an array of the new runners on base, and who scored.
  # @param runners [Array] The runners on base.
  # @param advance [Integer] The amount of bases to advance. Must be 1-4.
  # @param runner [String] The runner to advance.
  # @return [Array] The new runners on base.
  def advance_runners(runners, advance, runner)
    scored = []

    if runners.length != 3
      raise "Invalid runners: #{runners}"
    end

    # Count how many not 'nil' runners are on base
    on_base = 0
    runners.each do |run|
      on_base += 1 if run
    end

    case advance
    when 1 # Single, Walk, Hit By Pitch, etc.
      case on_base
      when 3
        # Shift the array 1 space to the right.
        scored.push runners[2]
        runners[2] = runners[1]
        runners[1] = runners[0]
        runners[0] = runner
      when 2
        # Delete all "nil" runners
        runners.delete_if { |e| e.nil? }
        # Add runner to the beginning of the array
        runners.unshift runner
      when 1
        runners[1] = runners[0] if runners[0]
        runners[0] = runner
      when 0
        runners[0] = runner
      else
        raise "Invalid on base: #{on_base}"
      end
    when 2 # Double
      # Anyone on 2nd or 3rd scores. The person on 1st, if any, goes to 3rd. The runner goes to 2nd.
      if on_base == 1 || on_base == 0
        runners[2] = runners[1] || runners[0]
        runners[1] = runner
      end
      if on_base >= 2
        first = nil
        runners.each do |run|
          first = run if run and not first
          scored.push run if run and first
        end
        runners[2] = first
        runners[1] = runner
      end
    when 3 # Triple
      # everyone on base scores, except the runner
      runners.each do |run|
        scored.push run if run
      end
      runners = [nil,nil,runner]
    when 4 # Home Run
      runners.each do |run|
        scored.push run if run
      end
      runners = [nil,nil,nil]
      scored.push runner
    else
      raise "Invalid advance amount: #{advance}"
    end

    [runners, scored]
  end

  def random_at_bat(in_play, strikeout, walks, hit_by_pitch, type = "no out")
    plays = []
    balls = 0
    strikes = 0
    play_done = false

    sample = ["Ball", "Swinging Strike", "Called Strike", "Ball In Dirt", "Foul"]
    sample.push "Hit By Pitch" if hit_by_pitch
    sample.push "In play, #{type}" if in_play

    puts "Sample is #{sample}"

    while balls < 4 and strikes < 3 and not play_done
      now = sample.sample
      puts "Generated: #{now}. Count is #{balls}-#{strikes}"

      if now.include? "Ball"
        if balls < 3
          balls += 1
        elsif balls == 3 and walks
          plays.push now
          return plays
        else
          next
        end
      end

      if now.include?("Strike")
        if strikes < 2
          strikes += 1
        elsif strikes == 2 and strikeout
          plays.push now
          return plays
        else
          next
        end
      end

      if now == "Foul"
        if strikes < 2
          strikes += 1
        end
      end

      if now.include? "In play"
        plays.push now
        return plays
      end

      if now == "Hit By Pitch"
        plays.push now
        return plays
      end

      plays.push now
    end

    plays
  end
end
