require 'nokogiri'
require 'open-uri'
require 'time'

# This parser is ONLY for mlb.mlb.com, which no longer exists. It can only be accessed through the Wayback Machine.
# As such, URLs generally start with web.archive.org/web/[date]/mlb.mlb.com; however, it can also include team names.
class MLBMLBComParser
  def self.parse(url)
    # get info
    html = URI.open(url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors

    # determine if byLine or not
    # aka check if #article_head > div.byLine exists
    if doc.css("#article_head > div.byLine").length > 0
      title = doc.css("#article_content > div > h1").text.strip
      title = doc.css("#article_content > div > h3").text.strip if title.empty?

      author = doc.css("#article_head > div.byLine").text.strip
      date = doc.css('#article_head > div.byLine > span').text.strip
    else
      title = doc.css('#mc > div > div.article-content > div.article-header > h1').text.strip
      author = doc.css("#mc > div > div.article-content > div.article-header > p").text.strip
      date = doc.css('#mc > div > div.article-content > div.article-header > p > span').text.strip
    end

    # we gotta clean up the date bro, ong
    date_split = date.split(" ").first.split("/")
    date_obj = Time.new("20#{date_split[2]}".to_i, date_split[0], date_split[1])

    info = {}

    author_name = author.split("By ").last.split(" / ").first
    author_parts = author_name.split(" ")
    if author_parts
      info[:last] = author_parts.pop
      info[:first] = author_parts.join(" ")
    end
    info[:date] = date_obj.strftime("%Y-%m-%d")
    info[:title] = title

    # for the normal url, it needs to be everything after the web.archive.org/web/[date]
    info[:url] = url.split("/")[5..].join("/")

    # Archive info
    archive_date = url.split("/")[4]
    info[:'archive-url'] = url
    info[:'archive-date'] = archive_date[0..3] + "-" + archive_date[4..5] + "-" + archive_date[6..7]

    info[:website] = "MLB.com"
    info[:language] = "en-US"

    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    return "{{Cite web |#{params}}}"
  end
end

#print MLBMLBComParser.parse("https://web.archive.org/web/20120501071405/http://detroit.tigers.mlb.com/news/article.jsp?ymd=20120430&content_id=30057550&vkey=news_det&c_id=det")