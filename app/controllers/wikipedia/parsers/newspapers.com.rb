require 'nokogiri'
require 'open-uri'

# city names so obvious that we do not need to include the location if it's in the newspaper name
EXCLUDED_LOCATIONS = [
  "New York, New York",
  "Atlanta, Georgia",
  "Los Angeles, California",
  "Detroit, Michigan",
  "Windsor, Ontario, Canada",
  "Fort Worth, Texas"
].freeze

class NewspapersComParser
  # Short link to do all the work for us
  def self.parse(url)
    NewspapersComParser.new(url).parse
  end

  def initialize(url)
    # If this is a proxied link, unproxy it
    @url = url.gsub("www-newspapers-com.wikipedialibrary.idm.oclc.org", "www.newspapers.com")

    # get info
    html = URI.open(@url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors
    @title = doc.css('#mainContent > div.page_Top__EQkc2 > h1').text.strip
    @description = doc.css('#mainContent > div.page_Middle__8g61Q > div.page_Main__uAaM_ > span.hideMobile > div.page_ArticleBody__OycTO').text.strip
    @publication = doc.css('#mainContent > div.page_Middle__8g61Q > div.page_SideBar__5Qzqx.hideMobile > div > a > h2').text.strip
    @location = doc.css('#mainContent > div.page_Middle__8g61Q > div.page_SideBar__5Qzqx.hideMobile > div > a > p').text.strip
    @date = doc.css('#mainContent > div.page_Middle__8g61Q > div.page_SideBar__5Qzqx.hideMobile > div > a > p > time').attr('datetime').value
    @page = doc.css('#mainContent > div.page_Middle__8g61Q > div.page_SideBar__5Qzqx.hideMobile > div > a > p > span').text.strip
  end

  def parse
    syndication = parse_syndication

    info = {}

    # parse in author info
    info = info.merge(parse_author)
    info[:date] = @date
    info[:title] = @title
    info[:url] = @url
    info[:'access-date'] = Time.now.utc.strftime("%Y-%m-%d")
    info[:work] = @publication
    info[:location] = syndication[:location] if syndication[:location]
    info[:page] = @page.split(" ").last
    info[:'publication-place'] = @location.split(' •')[0] unless obvious_location?
    info[:via] = "[[Newspapers.com]]"
    info[:agency] = syndication[:agency] if syndication[:agency]

    # build and return
    params = info.map { |k, v| "#{k}=#{v}" }.join(" |")

    "{{Cite news |#{params}}}"
  end

  # Parse the description for authors.
  # If there's multiple, it'll handle that too.
  def parse_author
    # Can't handle empty descriptions
    return {} if @description.empty?

    # Check if any line starts with "By "
    return {} unless @description.split("\n").any? { |line| line.start_with?("By ") }

    # Get the first line that starts with "By "
    author = @description.split("\n").find { |line| line.start_with?("By ") }

    # remove by
    author = author[3..-1]

    # Split by semicolon or commas
    authors = author.split(/[;,]/).map(&:strip)

    # map as last, first, last2, first2, etc
    author_map = {}

    authors.each_with_index do |ath, i|
      author_parts = ath.split(" ")
      i = nil if i == 0
      i = i + 1 if i
      author_map["last#{i}"] = author_parts.pop
      author_map["first#{i}"] = author_parts.join(" ")
    end

    author_map
  end

  def parse_syndication
    # Can't handle empty descriptions
    return {} if @description.empty?

    # Build info
    info = {}

    # Get everything after "Syndicated by"
    syndication = @description.split("\n").find { |line| line.start_with?("Syndicated by ") }

    if syndication
      syndication_parse = syndication[14..-1]

      # Check to see who it is
      case syndication_parse
      when "AP"
        info[:agency] = "Associated Press"
      when "UP"
        info[:agency] = "United Press"
      when "UPI"
        info[:agency] = "United Press International"
      when "INS"
        info[:agency] = "International News Service"
      else
        info[:agency] = syndication_parse
      end
    end

    # Syndicated from, but we don't need this.
    # syndication_from = @description.split("\n").find { |line| line.start_with?("Syndicated from ") }
    #
    # if syndication_from
    #   syn_from_parse = syndication_from[16..-1]
    #
    #   info[:location] = syn_from_parse
    # end

    info
  end

  # Locations so obvious we don't need them if the location is in the publication name
  def obvious_location?
    city = @location.split(', ')[0]

    EXCLUDED_LOCATIONS.include?(@location.split(' •')[0]) and @publication.include?(city)
  end
end
