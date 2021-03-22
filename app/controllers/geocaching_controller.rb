# frozen_string_literal: true

class GeocachingController < ApplicationController
  include Response
  include ActionView::Helpers::DateHelper
  skip_before_action :verify_authenticity_token
  # protect_from_forgery prepend: true
  before_action :goodbye_token

  def goodbye_token
    form_authenticity_token = nil
  end

  def handleemail
    #unless params['sender'].include?('@geocaching.com') || params['sender'].include?("mailgun") || params['sender'].include?("chew@chew")
    #  lesend("Invalid sender")
    #  json_response({ "error": 'invalid sender' }, 403)
    #  return
    #end

    unless params['From'].include?("@geocaching.com")
      json_response({ "error": 'invalid sender' }, 406)
      return
    end

    noko = Nokogiri::HTML.parse(params['body-html']).search('table.outer').at('tr').at('td').at('table').at('tr').at('td').text.delete('	').gsub("Remove this from my watchlist", '').split("\n")[5..-1]

    body = noko
    cache = body[0].split(' ')
    name = body[0].split(' (')[0]
    gcode = body[0].split(' (')[1].split(')')[0]
    by = body[3].split(': ').last.split(' <')[0]
    typ = body[4].split(': ').last
    log = params['stripped-text'].split("\n")[8..-1].join("\n").split("Remove this from my watchlist").first.chomp
    link = Nokogiri::HTML.parse(params['body-html']).at_xpath('/html[@xmlns="http://www.w3.org/1999/xhtml"]/body[@style="Margin:0;padding-top:0;padding-bottom:0;padding-right:0;padding-left:0;min-width:100%;background-color:#ffffff;"]/center[@class="wrapper"]/table[@width="100%"]/tr[2]/td[@width="100%"]/div[@class="webkit"]/table[@class="outer"]/tr/td[@style="padding-top:0;padding-bottom:0;padding-right:0;padding-left:0;"]/table[@class="one-column"]/tr/td/table[@width="100%"]/tr/td[@align="left"]/strong/a').to_s.split('"')[1]

    chars = "#{name} (#{gcode}) has a new log
    #{typ} by #{by}
    #{link}
    ".length

    log = if chars + log.length > 280
            "#{log[0..280 - chars - 3]}..."
          else
            log.strip
          end

    status = "#{name} (#{gcode}) has a new log\n#{typ} by #{by}\n\"#{log}\"\n#{link}"

    # Exchange our oauth_token and oauth_token secret for the AccessToken instance.
    access_token = prepare_access_token(Rails.application.credentials.geocaching[:oauth_token], Rails.application.credentials.geocaching[:oauth_token_secret])

    # use the access token as an agent to get the home timeline
    response = JSON.parse(access_token.request(:post, '/1.1/statuses/update.json', { "status" => status }, {'Content-Type' => 'application/json'}).body)

    json_response({"success": true, "tweet": status }, 200)
  end

  # Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
  def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(Rails.application.credentials.geocaching[:consumer_key], Rails.application.credentials.geocaching[:consumer_secret], site: 'https://api.twitter.com', scheme: :header)

    # now create the access token object from passed values
    token_hash = { oauth_token: oauth_token, oauth_token_secret: oauth_token_secret }
    OAuth::AccessToken.from_hash(consumer, token_hash)
  end
end
