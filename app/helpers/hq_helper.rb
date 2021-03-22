module HqHelper
  def get_user(key)
    get_data('users/me', key)
  end

  def get_data(endpoint, key)
    JSON.parse(RestClient.get("https://api-quiz.hype.space/#{endpoint}",
                              Authorization: key,
                              'x-hq-client': 'iOS/1.3.27 b121',
                              'Content-Type': :json))
  end
end
