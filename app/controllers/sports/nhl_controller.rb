class Sports::NhlController < SportsController
  def nhl_home
    @standings = JSON.parse(RestClient.get("https://statsapi.web.nhl.com/api/v1/standings", 'User-Agent': DUMMY_USER_AGENT))['records']
  end
end
