class SlackApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def rory
    id = params['text'].to_i

    id = "" if id.zero?

    rory = JSON.parse(RestClient.get("https://rory.cat/purr/#{id}"))

    response = {
      "response_type": "in_channel",
      "text": rory['url']
    }

    RestClient.post(params['response_url'], response.to_json, 'Content-Type': :json)
  end

  def trbmb
    words = TRBMB_WORDS

    words1 = words[0][13..-1].delete('"').split(',')
    words2 = words[2][13..-1].delete('"').split(',')

    response = {
      "response_type": "in_channel",
      "text": "That really #{words1.sample} my #{words2.sample}"
    }

    RestClient.post(params['response_url'], response.to_json, 'Content-Type': :json)
  end
end
