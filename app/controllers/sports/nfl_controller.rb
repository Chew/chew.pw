class Sports::NflController < SportsController
  # Dummy user agent for the NHL API
  NFL_USER_AGENT = "NFLMobile/14471 CFNetwork/1390 Darwin/22.0.0"

  # Cycles the NFL token.
  # It expires after one hour...
  def cycle_nfl_token
    data = {
      clientKey: Rails.application.credentials.nfl[:client_key],
      clientSecret: Rails.application.credentials.nfl[:client_secret],
      deviceId: Rails.application.credentials.nfl[:device_id],
      refreshToken: Rails.application.credentials.nfl[:refresh_token],
      deviceInfo: Rails.application.credentials.nfl[:device_info],
      networkType: "wifi",
      nflClaimGroupsToAdd: [],
      nflClaimGroupsToRemove: [],
      latitude: 38.897957,
      longitude: -77.036560
    }

    response = RestClient.post("https://api.nfl.com/identity/v3/token/refresh", data.to_json, content_type: :json, accept: :json)
    body = JSON.parse(response.body)

    Rails.application.credentials.nfl[:access_token] = body['accessToken']
    Rails.application.credentials.nfl[:refresh_token] = body['refreshToken']
  end

  def nfl_web_request(url, failed = false)
    begin
      JSON.parse(RestClient.get(url, Authorization: "Bearer #{Rails.application.credentials.nfl[:access_token]}", 'User-Agent': NFL_USER_AGENT))
    rescue RestClient::Unauthorized
      puts "Refreshing NFL token..."
      if failed
        # We failed once, so we can't do anything else
        raise RestClient::Unauthorized, "Failed to get NFL data"
      else
        # Retry
        cycle_nfl_token
        nfl_web_request(url, true)
      end
    end
  end

  def nfl
    @teams = nfl_web_request("https://api.nfl.com/football/v1/standings?season=2022&seasonType=REG")['weeks']
  end

  def nfl_team
    @schedule = nfl_web_request("https://api.nfl.com/football/v2/games/season/#{@season}/team/#{params[:team_id]}")['games']
  end

  def nfl_game
    @game = nfl_web_request("https://api.nfl.com/experience/v1/gamedetails/#{params[:game_id]}")['data']['viewer']['gameDetail']
  end
end
