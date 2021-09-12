class ApplicationController < ActionController::Base
  before_action :set_raven_context
  before_action :info
  skip_before_action :verify_authenticity_token, :only => [:flush]
  include Response

  def info
    @controller_name = request.controller_class.to_s.gsub("Controller", "").downcase

    @layout = Dir['app/views/layouts/extra/*'].map { |f| File.basename(f, '.html.erb') }.include? "_#{@controller_name}"
    @nav = Dir['app/views/layouts/navs/*'].map { |f| File.basename(f, '.html.erb') }.include? "_#{@controller_name}"
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
  def random_string(length = 25, chars = [('a'..'z'), ('A'..'Z')])
    o = chars.map(&:to_a).flatten
    (0...length).map { o[rand(o.length)] }.join
  end

  private

  def set_raven_context
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
