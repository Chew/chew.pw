class ApplicationController < ActionController::Base
  before_action :set_raven_context
  before_action :info

  def info
    @controller_name = request.controller_class.to_s.gsub("Controller", "").downcase

    @layout = Dir['app/views/layouts/extra/*'].map { |f| File.basename(f, '.html.erb') }.include? "_#{@controller_name}"
    @nav = Dir['app/views/layouts/navs/*'].map { |f| File.basename(f, '.html.erb') }.include? "_#{@controller_name}"
  end

  private

  def set_raven_context
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
