Rails.application.routes.draw do
  root 'front#index'
  get 'sitemap', to: 'front#sitemap'

  get 'birb', to: 'api#randombirb'

  post 'cache/flush', to: 'application#flush'

  scope 'util' do
    get 'image', to: 'api#url'
    get 'html', to: 'utilities#striphtml'
    post 'html/strip', to: 'utilities#strippedhtml'
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
    scope 'webhooks' do
      get '/', to: 'discord#webhook'
      post 'send', to: 'discord#send_hook'
    end
  end

  scope 'mc' do
    get '/', to: 'minecraft#index'
    get 'enchant', to: 'minecraft#mc-enchantment'
    get 'pro/status', to: redirect('/mcpro/status')
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

    get 'daily', to: 'hqbot#dailycheat'

    scope 'authkey' do
      get '', to: 'hqbot#authkey'
      post 'verify', to: 'hqbot#authkey_handle'
      post 'show', to: 'hqbot#authkey_conclude'
    end
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

  scope 'hq' do
    get '/', to: 'hq#index'
    get 'powerups', to: 'hq#powerups'
    get 'friends', to: 'hq#friends'
    get 'schedule', to: 'hq#schedule'
    get 'leaders', to: 'hq#leaders'
    get 'settings', to: 'hq#settings'
    get 'missing', to: 'hq#missing'
    post 'saveusername', to: 'hq#saveusername'

    get 'logout', to: 'hq#logout'
    get 'signin', to: 'hq#signin'
    post 'signin/code', to: 'hq#signinhandle'
    post 'signin/conclude', to: 'hq#signinconclude'

    get 'words/bots', to: 'hq#wordsbots'

    get 'question/beta', to: 'hq#question2'
    get 'endpoints', to: 'hq#endpoints'
    get 'random', to: 'hq#question'
  end

  # Secret routes
  (1..4).each do |i|
    post Rails.application.credentials.routes["post#{i}".to_sym], to: Rails.application.credentials.routes["to#{i}".to_sym]
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
