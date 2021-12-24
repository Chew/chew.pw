# The iFunny Controller handles all the iFunny nonsense
class IfunnyController < ApplicationController
  # The API Endpoint used in all requests
  API_ENDPOINT = 'https://api.ifunny.mobi/v4'.freeze
  # The Basic Authentication Token, required for signing in
  BASIC_TOKEN = Rails.application.credentials[:ifunny_basic_token]
  # A dummy user-agent to spoof who we are
  USER_AGENT = 'iFunny/7.9(21965) iphone/15.0 (Apple; iPhone13,1)'.freeze

  # Ensure the user is logged in... except doesn't matter for index or login pages
  before_action :verify_authenticated, except: %i[index login authenticate captcha]

  # @!group API helpers

  # Perform a simple GET request with all headers we need
  # @param path [String] The path
  # @param token [String] The auth token
  def get_request(path, token = "Bearer #{session[:ifunny_token]}")
    RestClient.get("#{API_ENDPOINT}#{path}",
                   Authorization: token, # Required
                   'ifunny-project-id': 'iFunny', # Required
                   'user-agent': USER_AGENT)
  end

  # Perform a simple GET request with all headers we need
  # @param path [String] The path
  # @param data [Enumerable] The data, un-encoded.
  # @param token [String] The auth token
  def post_request(path, data, token = "Bearer #{session[:ifunny_token]}")
    begin
      RestClient.post("#{API_ENDPOINT}#{path}",
                      URI.encode_www_form(data),
                      'Content-Type': 'application/x-www-form-urlencoded',
                      Authorization: token, # Required
                      'ifunny-project-id': 'iFunny', # Required
                      'user-agent': USER_AGENT)
    rescue RestClient::Forbidden, RestClient::TooManyRequests => e
      body = JSON.parse(e.response)
      if body['error'] == 'captcha_required'
        # "https://api.ifunny.mobi/verify.php?id=my_cool_id&project=iFunny"
        url = body['data']['captcha_url']

        # Get the ID from the url
        id = url.split('id=')[1].split('&')[0]

        # redirect to captcha page
        flash[:captcha_id] = id
        raise SecurityError.new, "Captcha required."
      end
      if body['error'] == 'too_many_user_auths'
        raise RestClient::TooManyRequests.new, "Too many user auths."
      end
    end
  end

  # @!endgroup

  # Ensure the user is logged in, or redirect them away if not
  def verify_authenticated
    redirect_to '/ifunny/login' unless session[:ifunny_token]
  end

  # Take login credentials and send them to iFunny to parse
  def authenticate
    data = {
      'email' => params['email'],
      'password' => params['password'],
      'grant_type' => 'password'
    }

    begin
      response = JSON.parse(post_request('/oauth2/token', data, BASIC_TOKEN))
    rescue SecurityError
      redirect_to "/ifunny/captcha?id=#{flash[:captcha_id]}"
      return
    rescue RestClient::TooManyRequests
      flash[:modal_js] = "Too many logins! Please try again later."
      redirect_to "/ifunny/login"
      return
    rescue RestClient::Unauthorized, RestClient::NotFound
      flash[:modal_js] = "No can do. Access denied."
      redirect_to "/ifunny/login"
      return
    end

    session[:ifunny_token] = response['access_token']

    redirect_to '/ifunny'
  end

  # Logout the user
  def logout
    session[:ifunny_token] = nil
    redirect_to '/ifunny/login'
  end

  # Get and view this user's account details
  def account
    @account = JSON.parse(get_request('/account'))['data']
  end

  # Get a comment
  def comment
    # If they filled out the form on /comment
    if !params['comment_link'].nil? && params['comment_link'].split('/').length >= 4
      # rebuild link
      exploded = params['comment_link'].split('/')
      meme_info = exploded[4].split('?')
      meme_id = meme_info[0]
      comment_id = meme_info[1].split('=')[1].split('&')[0]
      # redirect back to here properly
      redirect_to "/ifunny/content/#{meme_id}/comment/#{comment_id}"
    end

    # Render generic comment page if there isn't one provided
    return if params['meme_id'].nil? || params['comment_id'].nil?

    # Get comment
    request_data = JSON.parse get_request("/content/#{params['meme_id']}/comments?limit=1&show=#{params['comment_id']}&state")
    comment_data = request_data['data']['comments']['items']

    # If there's no comments
    if comment_data.empty?
      render file: "#{Rails.root}/public/404.html", status: :not_found
    end

    # If the first comment's ID doesn't match our comment ID, in which case the comment ID is invalid
    unless comment_data[0]['id'] == params['comment_id']
      render file: "#{Rails.root}/public/404.html" , status: :not_found
    end

    # Return our comment
    @comment = comment_data[0]
  end
end
