class ChewbotccaController < ApplicationController
  include Response
  skip_before_action :verify_authenticity_token
  before_action :goodbye_token

  def goodbye_token
    form_authenticity_token = nil
  end

  def commands
    command_list = {}
    commands_all = []
    commands = ChewbotccaCommand.all.to_a
    commands.each do |com|
      command_list[com.command] = com
      commands_all.push com.command
      next if com.aliases.nil?

      com.aliases.split(", ").each do |ali|
        command_list[ali] = com
        commands_all.push ali
      end
    end
    unless commands_all.include?(params['command'].downcase)
      dictionary = DidYouMean::SpellChecker.new(dictionary: commands_all)
      possible = dictionary.correct(params['command'].downcase)
      json_response({ "error": "invalid command", "didYouMean": possible }, 404)
      return
    end

    json_response(command_list[params['command'].downcase], 200)
  end

  def discord_commands
    @commands = ChewbotccaCommand.all.to_a
  end

  def api_get_profile
    unless request.headers["Authorization"] == Rails.application.credentials.chewbotcca
      json_response({ "error": "invalid auth" }, 401)
      return
    end

    profile = ChewbotccaProfile.find_by(userid: params['id'])
    if profile.nil?
      ChewbotccaProfile.create(userid: params['id'])
      profile = ChewbotccaProfile.find_by(userid: params['id'])
    end
    json_response(profile, 200)
  end

  def api_post_profile
    unless request.headers["Authorization"] == Rails.application.credentials.chewbotcca
      json_response({ "error": "invalid auth" }, 401)
      return
    end

    profile = ChewbotccaProfile.find_by(userid: params['id'])
    if profile.nil?
      ChewbotccaProfile.create(userid: params['id'])
      profile = ChewbotccaProfile.find_by(userid: params['id'])
    end
    profile.send(params.to_unsafe_h.first[0] + "=", params.to_unsafe_h.first[1])
    profile.save!
    json_response(profile, 200)
  end

  def api_delete_profile
    unless request.headers["Authorization"] == Rails.application.credentials.chewbotcca
      json_response({ "error": "invalid auth" }, 401)
      return
    end

    profile = ChewbotccaProfile.find_by(userid: params['id'])
    profile&.destroy!
    json_response({ success: true }, 200)
  end

  def api_get_server
    unless request.headers["Authorization"] == Rails.application.credentials.chewbotcca
      json_response({ "error": "invalid auth" }, 401)
      return
    end

    server = ChewbotccaServer.find_by(serverid: params['id'])
    if server.nil?
      ChewbotccaServer.create(serverid: params['id'])
      server = ChewbotccaServer.find_by(serverid: params['id'])
    end
    json_response(server, 200)
  end

  def api_post_server
    unless request.headers["Authorization"] == Rails.application.credentials.chewbotcca
      json_response({ "error": "invalid auth" }, 401)
      return
    end

    server = ChewbotccaServer.find_by(serverid: params['id'])
    if server.nil?
      ChewbotccaServer.create(serverid: params['id'])
      server = ChewbotccaServer.find_by(serverid: params['id'])
    end
    server.send(params.to_unsafe_h.first[0] + "=", params.to_unsafe_h.first[1])
    server.save!
    json_response(server, 200)
  end

  def slack_oauth
    url = "https://slack.com/api/oauth.v2.access"

    data = {
      code: params['code'],
      client_id: "135824302695.1690214909123",
      client_secret: Rails.application.credentials.slack[:oauth_secret]
    }

    RestClient.get(url + "?" + URI.encode_www_form(data), 'Content-Type': :json)
  end
end
