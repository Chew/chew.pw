# frozen_string_literal: true

class HqbotController < ApplicationController
  before_action :check_auth

  def check_auth
    @loggedin = false
    @as = nil

    lol = session[:id]
    @profile = HqBotProfile.find_by(userid: lol.to_i)
    unless lol.nil?
      cookie = session[:token]
      jj = HqBotLogin.find_by(userid: lol).access_token
      if cookie == jj
        @loggedin = true
        @as = Discord.user(lol).distinct
      end
    end
  end

  def index
    unless @loggedin
      respond_to do |format|
        format.html { render 'profile_loggedout' }
      end
      return
    end

    if @loggedin && @profile.nil?
      respond_to do |format|
        format.html { render 'profile_noprofile' }
      end
      return
    end

    @status = {
      authkey: "Auth Key Donor",
      donator: "Donator",
      bughunter: "Bug Hunter"
    }

    @settings = {
      lives: "Lives",
      streaks: "Streaks",
      erase1s: "Erasers",
      superspins: "Super Spins",
      coins: "Coins"
    }
  end

  def saveprofile
    username = params['username']
    username = Discord.user(session[:id]).name if username == ''
    region = params['region']

    lives = params['lives'] || 0
    streaks = params['streaks'] || 0
    erase1s = params['erase1s'] || 0
    superspins = params['superspins'] || 0
    coins = params['coins'] || 0

    begin
      user = HqBotProfile.find_by(userid: session[:id].to_i)
      user.username = username
      user.lives = lives
      user.streaks = streaks
      user.erase1s = erase1s
      user.superspins = superspins
      user.coins = coins
      user.save!
      flash[:modal_js] = 'Your profile has been saved!'
    rescue StandardError => e
      flash[:modal_js] = 'An error occurred!'
    end

    redirect_to '/hqbot'
  end

  def makeprofile
    loggedin = false
    as = nil

    lol = session[:id]
    unless lol.nil?
      cookie = session[:token]
      jj = HqBotLogin.find_by(userid: lol).access_token
      if cookie == jj
        loggedin = true
        as = Discord.user(lol).distinct
      end
    end

    if loggedin
      user = Discord.user(lol)
      HqBotProfile.create(userid: lol, username: user.name, region: 'us')
    end

    redirect_to '/hqbot'
  end

  def logout
    session[:id] = nil
    session[:token] = nil

    redirect_to '/hqbot'
  end

  def authkey_handle
    params['country'] = '1' if params['country'].nil?

    if params['phone'].to_i.to_s != params['phone'].to_s || params['phone'].to_i.zero?
      flash[:modal] = "Invalid phone number provided!"
      redirect_to "/hqbot/authkey"
      return
    end

    phone = "+#{params['country']}#{params['phone']}"

    requestparams = {
      'method' => 'sms',
      'phone' => phone
    }.to_json

    bob = RestClient.post('https://api-quiz.hype.space/verifications',
                          requestparams,
                          'x-hq-client': 'iOS/1.3.19 b107',
                          'Content-Type': :json)

    j = JSON.parse(bob)

    @verid = j['verificationId']
  end

  def authkey_conclude
    requestparams = {
      'code' => params['code']
    }.to_json

    bob = RestClient.post("https://api-quiz.hype.space/verifications/#{params['verificationId']}",
                          requestparams,
                          'x-hq-client': 'iOS/1.3.19 b107',
                          'Content-Type': :json)

    broke = false

    begin
      j = JSON.parse(bob)['auth']

      @code = j['authToken']
      @user = j['username']
    rescue StandardError
      @broke = true
    end
  end

  def authorize
    url = request.base_url

    if @loggedin
      redirect_to '/hqbot'
      return
    end

    code = params['code']

    uri = URI.parse('https://discordapp.com/api/v6/oauth2/token')
    discord_request = Net::HTTP::Post.new(uri)
    discord_request.content_type = 'application/x-www-form-urlencoded'
    discord_request.set_form_data(
      'client_id' => '578544051901431821',
      'client_secret' => Rails.application.credentials.hqbot[:oauth_secret],
      'grant_type' => 'authorization_code',
      'code' => code,
      'redirect_uri' => "#{url}/hqbot/authorize",
      'scope' => 'identify'
    )

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(discord_request)
    end
    # response.code

    bob = JSON.parse(response.body)

    data = JSON.parse(RestClient.get('https://discordapp.com/api/v6/users/@me', Authorization: "Bearer #{bob['access_token']}"))

    user = HqBotLogin.find_by(userid: data['id'])

    if user.nil?
      HqBotLogin.create(userid: data['id'], access_token: bob['access_token'], refresh_token: bob['refresh_token'])
    else
      user.access_token = bob['access_token']
      user.refresh_token = bob['refresh_token']
      user.save!
    end

    session[:id] = data['id']
    session[:token] = bob['access_token']

    redirect_to '/hqbot'
  end
end
