class WikipediaController < ApplicationController
  def parser
    @parsers = PARSERS
  end

  def parse
    url = params[:parse].to_s

    @parsed = parse_citation(url)
  end

  def parse_citation(url)
    clipboard_value = url
    if clipboard_value.empty?
      return { error: "No URL provided" }
    end

    url = URI.parse(clipboard_value)

    begin
      if clipboard_value.include?(".mlb.com/news/article.jsp")
        # run mlb.mlb.com.rb parser
        return { markup: MLBMLBComParser.parse(clipboard_value) }
      end

      case url.host
      when "www.newspapers.com", "www-newspapers-com.wikipedialibrary.idm.oclc.org"
        # run newspapers.com.rb parser
        return { markup: NewspapersComParser.parse(clipboard_value) }
      when "www.mlbtraderumors.com"
        return { markup: MLBTradeRumorsParser.parse(clipboard_value) }
      when "www.mlb.com"
        return { markup: MLBComParser.parse(clipboard_value) }
      when "www.washingtonpost.com"
        return { markup: WashingtonPostParser.parse(clipboard_value) }
      when "www.nytimes.com"
        return { markup: NYTimesParser.parse(clipboard_value) }
      when "www.genealogybank.com"
        return { markup: GenealogybankComParser.parse(clipboard_value) }
      else
        # show notification
        return { error: "No parser found for #{url.host}" }
      end
    rescue StandardError => e
      return { error: e  }
    end
  end
end
