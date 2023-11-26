class Games::RobloxController < GamesController
  def index
  end

  def badgestats
    @game = JSON.parse(RestClient.get("https://games.roblox.com/v1/games?universeIds=#{params['universe']}"))['data'][0]

    search_result = JSON.parse(RestClient.get("https://www.roblox.com/search/users/results?keyword=#{params['username']}&maxRows=1&startIndex=0"))

    userid = search_result['UserSearchResults'][0]['UserId']
    @name = search_result['UserSearchResults'][0]['Name']

    @badges = JSON.parse(RestClient.get("https://badges.roblox.com/v1/universes/#{params['universe']}/badges?cursor&limit=100&sortOrder=Asc"))['data']

    user = JSON.parse(RestClient.get("https://www.roblox.com/users/inventory/list-json?assetTypeId=21&pageNumber=1&sortOrder=Desc&userId=#{userid}&itemsPerPage=100"))

    if user['Data']['nextPageCursor'].nil?
      @user = user['Data']['Items']
    else
      @user = []

      @user += user['Data']['Items']

      until user['Data']['nextPageCursor'].nil?
        user = JSON.parse(RestClient.get("https://www.roblox.com/users/inventory/list-json?assetTypeId=21&pageNumber=1&sortOrder=Desc&userId=#{userid}&cursor=#{user['Data']['nextPageCursor']}&itemsPerPage=100"))
        @user += user['Data']['Items']
      end
    end

    @badges.sort_by! { |badge| badge['statistics']['awardedCount'] }.reverse!#.sort_by! { |badge| has_badge?(badge['name']) }.reverse
  end

  def has_badge?(badge_name)
    @user.each do |bad|
      return 1 if bad['Item']['Name'] == badge_name
    end
    0
  end
end
