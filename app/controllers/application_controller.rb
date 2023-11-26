class ApplicationController < ActionController::Base
  before_action :set_raven_context
  before_action :add_permissions_policy_header
  before_action :info
  skip_before_action :verify_authenticity_token, :only => [:flush]
  include Response

  # @!group Constants

  # Dummy User Agent
  DUMMY_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.113 Safari/537.36'

  # @!endgroup

  def info
    @controller_name = request.controller_class.to_s.gsub("Controller", "").downcase
    # get everything before ::
    controller_name = @controller_name.split("::")
    if controller_name[0] == "games"
      @controller_name = controller_name[1]
    else
      @controller_name = controller_name[0]
    end

    @layout = Dir['app/views/layouts/extra/*'].map { |f| File.basename(f, '.html.erb') }.include? "_#{@controller_name}"
    @navs = []
    @navs.push Dir['app/views/layouts/navs/*'].map { |f| File.basename(f, '.html.erb') }.find { |e| e == "_#{@controller_name}" }
    if request.path.include?("/sports/mlb/team")
      @navs.push "subnavs/_sports_mlb_team"
    end

    # Whether this request came from Discord
    @discord = request.user_agent == "Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)"
  end

  def flush
    unless request.headers["Authorization"] == Rails.application.credentials.flush_key
      json_response({}, 404)
      return
    end

    Rails.cache.clear
    json_response({ success: true }, 200)
  end

  # Generate a random string with a given length
  # @return [String] A randomized string
  # @raise [ArgumentError] if the kind is not of 'alphanumeric', 'base64' or 'uuid'
  def random_string(length = 25, kind = 'alphanumeric')
    case kind
    when 'alphanumeric'
      SecureRandom.alphanumeric length
    when 'base64'
      SecureRandom.base64 length
    when 'uuid'
      SecureRandom.uuid
    else
      raise ArgumentError, "Invalid kind, must be one of 'alphanumeric', 'base64' or 'uuid'"
    end
  end

  private

  # Adds a Permissions-Policy header to match our permissions policy
  def add_permissions_policy_header
    header = []

    Rails.application.config.permissions_policy.directives.each do |key, values|
      map = []
      values.each do |value|
        case value
        when "'none'"
          next
        when "'self'"
          map.push "self"
        else
          map.push "\"#{value}\""
        end
      end

      header.push "#{key}=(#{map.join(' ')})"
    end

    response.headers['Permissions-Policy'] = header.join(", ")
  end

  def set_raven_context
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
