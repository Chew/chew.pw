require 'nokogiri'
require 'time'
require_relative './util'

class NYTimesParser
  def self.parse(url)
    #if url.include?("/archives/")
      return parse_archive(url)
    #else
    #  return parse_article(url)
    #end
  end

  def self.parse_article(url)
    # todo
    "Not Done Yet"
  end

  def self.parse_archive(url)
    # get info
    html = Utils.simulate_browser(url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors
    title = doc.xpath('//*[@id="link-2157eb94"]').text.strip
    #author = doc.xpath('#main-content-area > article > header > p > span > a > span').text.strip
    date = doc.xpath('//*[@id="story"]/header/div[4]/time').attr('datetime').value
    page = doc.xpath('//*[@id="story"]/section/div[1]/div/div[1]/div[2]/div[1]').text

    info = {}

    # author_parts = author.split(" ")
    # if author_parts
    #   info[:last] = author_parts.pop
    #   info[:first] = author_parts.join(" ")
    # end
    info[:date] = Time.parse(date).strftime("%Y-%m-%d")
    info[:title] = title
    info[:url] = url
    info[:'access-date'] = Time.now.utc.strftime("%Y-%m-%d")
    info[:work] = "[[The New York Times]]"
    info[:page] = page.split("Page ").last.split("Buy Reprints").first.strip

    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    return "{{Cite news |#{params}}}"
  end
end
