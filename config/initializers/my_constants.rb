TRBMB_WORDS = RestClient.get('https://trbmb.chew.pw/assets/js/words.js').body.to_s.split("\n")

ACRONYM_LIST = RestClient.get('https://acronym.chew.pro/assets/js/words.js').body.split("\n")

SPIGOT_DRAMA = JSON.parse(RestClient.get("https://raw.githubusercontent.com/md678685/spigot-drama-generator/master/src/data.json"))

Discord = Discordrb::Bot.new(
  token: Rails.application.credentials.discord[:token]
)
