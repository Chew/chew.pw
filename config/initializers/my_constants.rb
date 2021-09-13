Discord = Discordrb::Bot.new(
  token: Rails.application.credentials.discord[:token]
)
