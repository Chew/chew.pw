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

class GenealogybankComParser
  # Short link to do all the work for us
  def self.parse(url)
    GenealogybankComParser.new(url).parse
  end

  def initialize(url)
    # If this is a full URL, fix it
    clip_id = url.include?("clipid") ? url.split('?clipid=')[1] : url.split('/').last
    @url = "https://www.genealogybank.com/newspaper-clippings/title/#{clip_id}"

    # get info
    html = Utils.simulate_browser(@url)
    doc = Nokogiri::HTML(html)

    # Extract the elements based on the provided CSS selectors
    @title = doc.css('#block-system-main > div > div > div.col-md-7 > div.panel.panel-default.clipping-preview-component > div.panel-heading > h5:nth-child(2) > strong').text.strip
    @description = doc.css('#block-system-main > div > div > div.col-md-7 > div.panel.panel-default.clipping-preview-component > div.panel-heading > h5:nth-child(3) > strong').text.strip
    @publication = doc.css('#block-system-main > div > div > div.col-md-5 > div.row.m-t10 > div.col-md-7.col-sm-7.col-xs-9 > dl > dd:nth-child(1) > a > span').text.strip
    @location = doc.css('#block-system-main > div > div > div.col-md-5 > div.row.m-t10 > div.col-md-7.col-sm-7.col-xs-9 > dl > dd:nth-child(2)').text.strip
    @date = doc.css('#block-system-main > div > div > div.col-md-5 > div.row.m-t10 > div.col-md-7.col-sm-7.col-xs-9 > dl > dd:nth-child(3) > span').attr('content').value
    @page = doc.css('#block-system-main > div > div > div.col-md-5 > div.row.m-t10 > div.col-md-7.col-sm-7.col-xs-9 > dl > dd:nth-child(3)').text.strip.split(' Page')[1].strip
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
    info[:via] = "[[GenealogyBank.com]]"
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
