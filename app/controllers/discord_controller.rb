require 'discordrb/webhooks'

class DiscordController < ApplicationController
  def avataryeeter
    id = params['id'].to_i

    url = Discord.user(id).avatar_url.gsub('.webp', '.png')

    if params['size'].nil?
      redirect_to url
    else
      redirect_to url + "?size=#{params['size']}"
    end
  end

  def send_hook
    begin
      client = Discordrb::Webhooks::Client.new(url: params['webhook'])
      client.execute do |builder|
        builder.content = params['content']
        builder.username = params['wh_username']
        builder.avatar_url = params['wh_avatar']
        builder.add_embed do |embed|
          embed.title = params['title']
          embed.colour = params['color']
          embed.url = params['url']
          embed.description = params['description']
          embed.timestamp = Time.parse(params['timestamp']) unless params['timestamp'] == ''

          embed.image = Discordrb::Webhooks::EmbedImage.new(url: params['image_url'])
          embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: params['thumbnail_url'])
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: params['author_text'], url: params['author_link'], icon_url: params['author_url'])
          embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: params['footer_text'], icon_url: params['footer_url'])
        end
      end
      flash[:modal_js] = 'Sent!'
    rescue StandardError => e
      flash[:modal_js] = "Error! #{e.message}"
    end

    redirect_to "/webhooks"
  end

  def servers
    if session[:discord_key].nil?
      session[:scope] = "guilds"
      flash[:view_type] = "Server"
      session[:view_slug] = "servers"
      render 'signin'
      return
    end

    begin
      @servers = JSON.parse(RestClient.get("https://discord.com/api/v9/users/@me/guilds", Authorization: session[:discord_key]))
    rescue RestClient::Unauthorized
      redirect_to "/discord/servers/logout"
      return
    end
  end

  def connections
    if session[:discord_key].nil?
      session[:scope] = "connections"
      flash[:view_type] = "Connection"
      render 'signin'
      return
    end

    begin
      @connections = JSON.parse(RestClient.get("https://discord.com/api/v10/users/@me/connections", Authorization: session[:discord_key]))
    rescue RestClient::Unauthorized
      redirect_to "/discord/connections/logout"
      return
    end
  end

  def viewer_callback
    uri = URI.parse('https://discord.com/api/v6/oauth2/token')
    discord = Net::HTTP::Post.new(uri)
    discord.content_type = 'application/x-www-form-urlencoded'
    discord.set_form_data(
      'client_id' => '758151124413972492',
      'client_secret' => Rails.application.credentials.discord[:oauth_secret],
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => request.base_url + request.path,
      'scope' => session[:scope]
    )

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(discord)
    end
    # response.code

    bob = JSON.parse(response.body)

    session[:discord_key] = "Bearer #{bob['access_token']}"
    redirect_to "/discord/#{params['path']}"
  end

  def viewer_logout
    session[:discord_key] = nil
    redirect_to "/discord/#{params['path']}"
  end
end
