Rails.application.routes.draw do
  root 'front#index'
  get 'sitemap', to: 'front#sitemap'
  get 'privacy', to: 'front#privacy'

  post 'cache/flush', to: 'application#flush'

  scope 'util' do
    get 'image', to: 'api#url'
    get 'html', to: 'utilities#striphtml'
    post 'html/strip', to: 'utilities#strippedhtml'
    get 'random', to: 'utilities#random'
    get 'bases', to: 'utilities#bases'
    get 'aa', to: 'utilities#aa'
    post 'aa/calculate', to: 'utilities#calculate_aa'
  end

  scope 'api' do
    get 'trbmb', to: 'api#trbmb'
    get 'acronym/:acronym', to: 'api#acronym'
    get 'chewspeak', to: 'api#chewspeak'
    get 'random', to: 'api#random_string'
    get 'spigotdrama', to: 'api#spigot_drama'
    get 'apod', to: 'api#apod'

    scope 'slack' do
      post 'rory', to: 'slack_api#rory'
      post 'trbmb', to: 'slack_api#trbmb'
    end

    scope 'sports' do
      get 'nfl', to: 'sports#nfl_api'
    end

    scope 'chess' do
      scope 'uscf' do
        get 'member/:uscf_id', to: 'api#uscf_user'
      end
    end
  end

  get 'trbmb', to: redirect("/api/trbmb")
  get 'acronym/:acronym', to: redirect("/api/acronym/%{acronym}")
  get 'chewspeak', to: redirect("/api/chewspeak")

  get 'vaccine', to: 'utilities#vaccine'

  scope 'games' do
    # Cookies, Inc.
    scope 'cookiesinc' do
      get '/', to: 'games/cookiesinc#home'
      get '/team/:id', to: 'games/cookiesinc#team'
      get 'team/:id/neighboring', to: 'games/cookiesinc#neighboringteams'
      get 'team/:id/neighbouring', to: 'games/cookiesinc#neighboringteams'
      get '/teams/top', to: 'games/cookiesinc#topteams'
    end

    # ROBLOX
    scope 'roblox' do
      get '/', to: 'games/roblox#index'
      get 'badges', to: 'games/roblox#badges'
      get 'badges/stats', to: 'games/roblox#badgestats'
    end

    # Solitaire
    scope 'solitaire' do
      get 'challenges', to: 'games/solitaire#challenges_list'
      get 'challenges/:month/:year', to: 'games/solitaire#challenges'
    end

    # NY Times
    scope 'nytimes' do
      get '/', to: 'games/nytimes#index'
      scope 'wordle' do
        get '/', to: 'games/nytimes#wordle'
        post 'solve', to: 'games/nytimes#wordle_solve'
        get 'all', to: 'games/nytimes#wordle_all'
        get 'answer/:date', to: 'games/nytimes#wordle_answer'
      end
      get 'connections', to: 'games/nytimes#connections'
    end
  end

  # Handle old redirects
  get 'solitaire', to: redirect('/games/solitaire')
  get 'solitaire/:path', to: redirect('/games/solitaire/%{path}'), constraints: { path: /.*/ }
  get 'roblox', to: redirect('/games/roblox')
  get 'roblox/:path', to: redirect('/games/roblox/%{path}'), constraints: { path: /.*/ }
  get 'cookiesinc', to: redirect('/games/cookiesinc')
  get 'cookiesinc/:path', to: redirect('/games/cookiesinc/%{path}'), constraints: { path: /.*/ }
  get 'util/wordle', to: redirect('/games/nytimes/wordle')
  get 'util/wordle/:path', to: redirect('/games/nytimes/wordle/%{path}'), constraints: { path: /.*/ }
  get 'util/connections', to: redirect('/games/nytimes/connections')

  get 'webhooks', to: redirect("/discord/webhooks")

  scope 'discord' do
    get '/', to: 'discord#index'
    get 'webhook', to: redirect("/discord/webhooks")
    get 'avatar/:id', to: 'discord#avataryeeter'
    get ':path/logout', to: 'discord#viewer_logout'
    get ':path/callback', to: 'discord#viewer_callback'
    get 'servers', to: 'discord#servers'
    get 'connections', to: 'discord#connections'
    get 'timestamp', to: 'discord#timestamp'
    post 'timestamp/generate', to: 'discord#timestamp'
    scope 'webhooks' do
      get '/', to: 'discord#webhook'
      post 'send', to: 'discord#send_hook'
    end
  end

  scope 'mc' do
    get '/', to: 'minecraft#index'
    get 'enchant', to: 'minecraft#mc-enchantment'
    scope 'jars' do
      get '', to: 'minecraft#jars'
      scope 'build' do
        get ':type', to: 'minecraft#get_build'
        get ':type/:version', to: 'minecraft#get_build', constraints: { version: %r{[^\/]+} }
      end
      scope ':type' do
        get '', to: 'minecraft#download_jar'
        get ':version', to: 'minecraft#download_jar', constraints: { version: %r{[^\/]+} }
      end
    end
    scope 'log' do
      get '', to: 'minecraft#loganalyzer'
      post 'analyze', to: 'minecraft#analyzelog'
      get 'change', to: 'minecraft#logchangelog'
    end
    scope 'favicon' do
      get '', to: 'minecraft#favicon'
      get 'download', to: 'minecraft#download_favicon'
      get 'submit', to: redirect("/mc/favicon")
      post 'submit', to: 'minecraft#favicon_handle'
    end
  end

  scope 'ifunny' do
    get '/', to: 'ifunny#index'
    get '/login', to: 'ifunny#login'
    post '/login', to: 'ifunny#authenticate'
    get '/logout', to: 'ifunny#logout'

    get 'account', to: 'ifunny#account'
    get 'comment', to: 'ifunny#comment'

    get 'content/:meme_id/comment/:comment_id', to: 'ifunny#comment'

    # Human verification
    get 'captcha', to: 'ifunny#captcha'
  end

  get 'siri/hq/:username', to: 'api#hq'

  scope 'chewbotcca' do
    get '/', to: 'chewbotcca#home'
    scope 'discord' do
      get '/', to: 'chewbotcca#discord'
      get 'commands', to: 'chewbotcca#discord_commands'
      get 'api/command/:command', to: 'chewbotcca#commands'
      get 'privacy', to: 'chewbotcca#discord_privacy'
    end
    scope 'slack' do
      get '/', to: 'chewbotcca#slack'
      get 'privacy', to: 'chewbotcca#slack_privacy'
      get 'support', to: 'chewbotcca#slack_support'
      get 'oauth', to: 'chewbotcca#slack_oauth'
    end
  end

  scope 'sports' do
    # Football (National Football League)
    scope 'nfl' do
      get '/', to: 'sports/nfl#nfl'
      get '/game/:game_id', to: 'sports/nfl#nfl_game'
      get '/team/:team_id', to: 'sports/nfl#nfl_team'
    end

    scope 'mlb' do
      get '/', to: 'sports/mlb#mlb'
      get 'schedule', to: 'sports/mlb#mlb_schedule'
      get 'draft/:year', to: 'sports/mlb#mlb_draft'
      get 'teams', to: 'sports/mlb#mlb_teams'
      scope 'team' do
        scope ':team_id' do
          get '', to: 'sports/mlb#mlb_team'
          get 'affiliates', to: 'sports/mlb#mlb_team_affiliates'
          get 'homers', to: 'sports/mlb#team_homers'
        end
      end
      get 'game/generator', to: 'sports/mlb#mlb_game_generator'
      get 'game/:game_id', to: 'sports/mlb#mlb_game'
      get 'derby/:game_id', to: 'sports/mlb#mlb_derby'
    end

    # Hockey (National Hockey League)
    scope 'nhl' do
      get '/', to: 'sports/nhl#nhl_home'
    end
  end

  # Secret routes
  (1..2).each do |i|
    post Rails.application.credentials.routes["post#{i}".to_sym], to: Rails.application.credentials.routes["to#{i}".to_sym]
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
