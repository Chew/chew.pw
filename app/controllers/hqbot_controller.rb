# frozen_string_literal: true

# The main controller for HQ Trivia Discord Bot and getting an Auth-key
class HqbotController < ApplicationController
  before_action :check_auth

  # Check to see if the user is logged in, pluck data if they are
  def check_auth
    # Check session
    @loggedin = !session[:hqbot_id].nil?

    return unless @loggedin

    # Grab their profile
    @profile = HqBotProfile.find_by(userid: session[:hqbot_id].to_i)
  end

  # Load the main bot profile page
  def index
    # Return a "logged out" page if not signed in
    unless @loggedin
      respond_to do |format|
        format.html { render 'profile_loggedout' }
      end
      return
    end

    # Return a "no profile" page if no profile
    if @loggedin && @profile.nil?
      respond_to do |format|
        format.html { render 'profile_noprofile' }
      end
      return
    end

    # Helper variables to condense the code in the view
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

  # Save a bot profile
  def saveprofile
    # Use the inputted usernamne, or their Discord name if they sneaky
    username = params['username']
    username = session[:hqbot_username] if username == ''

    # Pluck authkey options
    lives = params['lives'] || 0
    streaks = params['streaks'] || 0
    erase1s = params['erase1s'] || 0
    superspins = params['superspins'] || 0
    coins = params['coins'] || 0

    # Attempt to save data
    begin
      user = HqBotProfile.find_by(userid: session[:hqbot_id].to_i)
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

    # Redirect back home
    redirect_to '/hqbot'
  end

  # Create a profile and return back to home
  def makeprofile
    if @loggedin
      HqBotProfile.create(userid: session[:hqbot_id], username: session[:hqbot_username], region: 'us')
    end

    redirect_to '/hqbot'
  end

  # Log out the user, nilling their info
  def logout
    session[:hqbot_id] = nil
    session[:hqbot_username] = nil

    redirect_to '/hqbot'
  end

  # Handle initial auth key input
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

  # Conclude the process and return their key
  def authkey_conclude
    requestparams = {
      'code' => params['code']
    }.to_json

    bob = RestClient.post("https://api-quiz.hype.space/verifications/#{params['verificationId']}",
                          requestparams,
                          'x-hq-client': 'iOS/1.3.19 b107',
                          'Content-Type': :json)

    begin
      j = JSON.parse(bob)['auth']

      @code = j['authToken']
      @user = j['username']
    rescue StandardError
      @broke = true
    end
  end

  # Login and authenticate the user through Discord
  def authorize
    # Ensure we aren't already signed in
    if @loggedin || params['code'].nil?
      redirect_to '/hqbot'
      return
    end

    # Build the form body
    body = {
      'client_id' => '578544051901431821',
      'client_secret' => Rails.application.credentials.hqbot[:oauth_secret],
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => "#{request.base_url}/hqbot/authorize",
      'scope' => 'identify'
    }

    # Get key info from Discord
    info = JSON.parse(RestClient.post('https://discord.com/api/v9/oauth2/token', URI.encode_www_form(body)))

    # Get Username and ID from Discord
    data = JSON.parse(RestClient.get('https://discord.com/api/v9/users/@me', Authorization: "Bearer #{info['access_token']}"))

    # Store information from Discord
    session[:hqbot_id] = data['id']
    session[:hqbot_username] = data['username']

    # Redirect home
    redirect_to '/hqbot'
  end
end
