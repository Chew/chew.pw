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
    get 'wordle', to: 'utilities#wordle'
    post 'wordle/solve', to: 'utilities#wordle_solve'
    get 'wordle/all', to: 'utilities#wordle_all'
    get 'bases', to: 'utilities#bases'
  end

  scope 'api' do
    get 'trbmb', to: 'api#trbmb'
    get 'acronym/:acronym', to: 'api#acronym'
    get 'chewspeak', to: 'api#chewspeak'
    get 'random', to: 'api#random_string'
    get 'spigotdrama', to: 'api#spigot_drama'

    scope 'slack' do
      post 'rory', to: 'slack_api#rory'
      post 'trbmb', to: 'slack_api#trbmb'
    end

    scope 'sports' do
      get 'nfl', to: 'sports#nfl_api'
    end
  end

  get 'trbmb', to: redirect("/api/trbmb")
  get 'acronym/:acronym', to: redirect("/api/acronym/%{acronym}")
  get 'chewspeak', to: redirect("/api/chewspeak")

  get 'vaccine', to: 'utilities#vaccine'

  scope 'cookiesinc' do
    get '/', to: 'cookiesinc#home'
    get '/team/:id', to: 'cookiesinc#team'
    get 'team/:id/neighboring', to: 'cookiesinc#neighboringteams'
    get 'team/:id/neighbouring', to: 'cookiesinc#neighboringteams'
    get '/teams/top', to: 'cookiesinc#topteams'
  end

  scope 'roblox' do
    get '/', to: 'roblox#index'
    get 'badges', to: 'roblox#badges'
    get 'badges/stats', to: 'roblox#badgestats'
  end

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

  scope 'hqbot' do
    get '', to: 'hqbot#index'
    get 'login', to: 'hqbot#login'
    get 'logout', to: 'hqbot#logout'
    get 'authorize', to: 'hqbot#authorize'
    post 'saveprofile', to: 'hqbot#saveprofile'
    post 'makeprofile', to: 'hqbot#makeprofile'
    get 'resetprofile', to: 'hqbot#resetprofile'

    scope 'authkey' do
      get '', to: 'hqbot#authkey'
      post 'verify', to: 'hqbot#authkey_handle'
      post 'show', to: 'hqbot#authkey_conclude'
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

  scope 'solitaire' do
    get 'challenges/:month/:year', to: 'solitaire#challenges'
  end

  scope 'sports' do
    scope 'nfl' do
      get '/', to: 'sports#nfl'
      get '/game/:game_id', to: 'sports#nfl_game'
    end

    scope 'mlb' do
      get '/', to: 'sports#mlb'
      get 'schedule', to: 'sports#mlb_schedule'
      get 'draft/:year', to: 'sports#mlb_draft'
      get 'teams', to: 'sports#mlb_teams'
      scope 'team' do
        scope ':team_id' do
          get '', to: 'sports#mlb_team'
          get 'affiliates', to: 'sports#mlb_team_affiliates'
        end
      end
      get 'game/generator', to: 'sports#mlb_game_generator'
      get 'game/:game_id', to: 'sports#mlb_game'
      get 'derby/:game_id', to: 'sports#mlb_derby'
    end
  end

  # Secret routes
  (1..2).each do |i|
    post Rails.application.credentials.routes["post#{i}".to_sym], to: Rails.application.credentials.routes["to#{i}".to_sym]
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
