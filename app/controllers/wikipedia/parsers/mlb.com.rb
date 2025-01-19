require 'nokogiri'
require 'open-uri'
require 'time'

class MLBComParser
  def self.parse(url)
    # get info
    html = URI.open(url)
    doc = Nokogiri::HTML(html)

    if url.include?('/press-release/')
      # no author, and we need to use cite press release
      press_release = true
    end

    # Extract the elements based on the provided CSS selectors
    title = doc.css('#skip-to-main-content > h1').text.strip
    # use xpath: //*[@id="skip-to-main-content"]/div[1]
    date = doc.xpath('//*[@id="skip-to-main-content"]/div[1]').text.strip
    author = doc.xpath('//*[@id="skip-to-main-content"]/div[2]/div/div[1]/div/p').text.strip

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
    info[:website] = "MLB.com"
    info[:language] = "en-US"

    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    cite_type = press_release ? "press release" : "web"

    return "{{Cite #{cite_type} |#{params}}}"
  end
end
