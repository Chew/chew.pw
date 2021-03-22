require 'discordrb/webhooks'

class MemeratorController < ApplicationController
  include Response
  include ActionView::Helpers::DateHelper
  skip_before_action :verify_authenticity_token
  # protect_from_forgery prepend: true
  before_action :goodbye_token

  def goodbye_token
    form_authenticity_token = nil
  end

  def status_update
    unless params['From'].include?("uptimerobot.com")
      json_response({ "error": 'invalid sender' }, 406)
      return
    end

    subject = params['Subject']
    up = subject.split(':').first.split(' ').last == 'UP'
    site = subject.split(':').last

    hookurl = Rails.application.credentials.memerator[:status_webhook]

    client = Discordrb::Webhooks::Client.new(url: hookurl)
    client.execute do |builder|
      builder.add_embed do |embed|
        embed.title = subject.split(':').first.gsub('Monitor', 'Site')
        embed.url = "https://status.memerator.me/"
        embed.description = "#{site} is #{subject.split(':').first.split(' ').last}"

        case up
        when true
          embed.color = '00ff00'
        when false
          embed.color = 'ff0000'
        end
      end
    end

    json_response({"success": true }, 200)
  end
end
