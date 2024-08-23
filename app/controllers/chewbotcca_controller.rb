class ChewbotccaController < ApplicationController
  include Response

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
