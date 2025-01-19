require 'nokogiri'
require 'open-uri'
require 'time'

class MLBTradeRumorsParser
  def self.parse(url)
    # get info
    html = URI.open(url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors
    title = doc.css('#main-content-area > article > header > h1').text.strip
    author = doc.css("#main-content-area > article > header > p > span > a > span").text.strip
    date = doc.css('#main-content-area > article > header > p > time:nth-child(2)').attr('datetime').value

    info = {}

    author_parts = author.split(" ")
    if author_parts
      info[:last] = author_parts.pop
      info[:first] = author_parts.join(" ")
    end
    info[:date] = Time.parse(date).strftime("%Y-%m-%d")
    info[:title] = title
    info[:url] = url
    info[:'access-date'] = Time.now.utc.strftime("%Y-%m-%d")
    info[:website] = "MLB Trade Rumors"
    info[:language] = "en-US"

    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    return "{{Cite web |#{params}}}"
  end
end