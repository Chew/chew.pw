class CookiesincController < ApplicationController
  def team
    begin
      data = JSON.parse(RestClient.get("https://ccprodapi.pixelcubestudios.com/Team/#{params['id']}"))
    rescue RestClient::InternalServerError
      @exist = false
      return
    end

    @name = data['teamName']
    @description = data['description']
    @players = data['players'].sort_by { |e| [e['seasonCollected'].to_f, e['lifetimeCollected'].to_f] }.reverse
    @total = data['collectedCookieCount']
    @rank = data['rank']
  end

  def topteams
    @teams = JSON.parse(RestClient.get("https://ccprodapi.pixelcubestudios.com/Team/TopTeams"))['teams']
  end

  def neighboringteams
    data = JSON.parse(RestClient.get("https://ccprodapi.pixelcubestudios.com/Team/NeighbouringTeams/#{params['id']}"))
    @teams = data['teams']
    @name = @teams[10]['teamName']
  end
end
