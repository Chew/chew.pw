require 'nokogiri'
require 'open-uri'
require 'time'
require_relative './util'

class WashingtonPostParser
  def self.parse(url)
    # get info
    html = Utils.simulate_browser(url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors
    title = doc.xpath('//*[@id="main-content"]/span').text.strip
    author = doc.xpath('//*[@id="__next"]/div[7]/main/article/div[2]/div[1]/div/div/div[1]/div/div/span/div/div/a').text.strip
    date = doc.xpath('//*[@id="__next"]/div[7]/main/article/div/div[1]/div/div/div[2]/time').attr('datetime').value

    puts date

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
    info[:website] = "The Washington Post"
    info[:language] = "en-US"

    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    return "{{Cite web |#{params}}}"
  end
end
