# Manages requests whose response is always JSON, never a page
# Most is documented here: https://api.chew.pro
# If it's not there, don't use it.
class ApiController < ApplicationController
  include Response
  skip_before_action :verify_authenticity_token

  # Returns a random string of x length
  # @return [Response, nil] JSON response of the string
  def random_string
    begin
      # Call "super", or the ApplicationController's random_string method
      value = super(params['length']&.to_i || 16, params['kind'] || 'alphanumeric')
      json_response({ response: value, success: true }, 200)
    rescue ArgumentError => e
      json_error_response e.message
    end
  end

  # Generates a random TRBMB phrase
  def trbmb
    many = request.headers['amount']&.to_i || params['amount']&.to_i || 1
    many = 1000 if many > 1000
    many = 1 if many < 1
    words = Rails.cache.fetch("api-trbmb-words") do
      JSON.parse(RestClient.get("https://trbmb.chew.pw/assets/json/words.json"))
    end

    output = []
    many.times do
      output += ["That really #{words['word1'].sample} my #{words['word2'].sample}"]
    end

    json_response(output)
  end

  # Fills in a given acronym
  def acronym
    acronym = params['acronym'].downcase.split('')
    phrase = []
    words = {}
    acronyms = Rails.cache.fetch("api-acronyms") do
      JSON.parse(RestClient.get("https://acronym.chew.pro/assets/json/words.json"))
    end
    acronyms.each do |letter, word_list|
      words[letter] = word_list.split(',')
    end
    acronym.each do |i|
      next if words[i].nil?

      phrase.push words[i].sample
    end

    json_response({ phrase: phrase.join(' ') }, 200)
  end

  def chewspeak
    input = params['input']
    # Ensure an input has been provided
    if input.nil?
      return json_error_response "missing 'input' parameter"
    end
    strings = input.split(' ')

    output = []

    strings.each do |string|
      string_io = StringIO.new(string)

      ar = []

      string_io.each(2) do |substring|
        ar.push substring
      end

      ar.each_with_index do |item, i|
        ar[i] = "#{item}#{item[0]}" unless item.length == 1
      end

      output.push ar.join('')
    end

    json_response({ input: params['input'], output: output.join(' ') }, 200)
  end

  # Generate some random Spigot Drama
  def spigot_drama
    drama = Rails.cache.fetch("api-spigot-drama") do
      JSON.parse(RestClient.get("https://raw.githubusercontent.com/md678685/spigot-drama-generator/master/src/data.json"))
    end

    combinations = drama['combinations']
    sentences = drama['sentences']

    base64 = {}

    sentence = sentences.sample
    base64['sentence'] = sentences.index { |e| e == sentence }
    while sentence.include? "["
      combinations.each do |key, _|
        placeholder = "[#{key}]"
        replacement = combinations[key].sample
        i = combinations[key].index { |e| e == replacement }
        next unless sentence.include? placeholder

        sentence = sentence.sub(placeholder, replacement)
        if base64[key].nil?
          base64[key] = [i]
        else
          base64[key].push i
        end
      end
    end

    json_response({ response: sentence, permalink: "https://drama.essentialsx.net/#{Base64.encode64(base64.to_json.to_s).gsub("\n", "")}" }, 200)
  end

  # Grabs a photo from the NASA Astronomy Picture of the Day page
  # Date format is YYMMDD
  # @return [Response, nil] JSON response of the photo
  def apod
    data = RestClient.get("https://apod.nasa.gov/apod/ap#{params[:date]}.html")

    doc = Nokogiri::HTML.parse(data)

    title = doc.xpath("/html/body/center[2]/b[1]").text.strip
    friendlyDate = "Date: " + doc.xpath("/html/body/center[1]/p[2]/text()").text.strip
    image = doc.xpath("/html/body/center[1]/p[2]/a/img")
    description = image.attr("alt")&.value&.gsub("\n", " ")&.strip
    img = "https://apod.nasa.gov/apod/#{image.attr("src")&.value&.strip}"
    explanation = doc.xpath("/html/body/p[1]").text.gsub("\n", " ").gsub("  ", " ").strip

    # Ensure img is a valid image
    img = nil if img == "https://apod.nasa.gov/apod/"

    json_response({ friendlyDate: friendlyDate, title: title, description: description, img: img, explanation: explanation }, 200)
  end

  def uscf_user
    page = Rails.cache.fetch("api-uscf-#{params[:uscf_id]}", expires_in: 1.day) do
      RestClient.get("https://www.uschess.org/msa/MbrDtlMain.php?#{params[:uscf_id]}").body
    end

    doc = Nokogiri::HTML.parse(page)

    elements = []
    doc.css("tr").each do |element|
      elements << element.text
    end

    elements.map! { |e| e.strip.gsub("\n", " ") }

    response = {
      member: {
        id: elements[4].split(':').first.to_i,
        name: elements[4].split(': ').last,
      },
      ratings: {
        regular: {},
        quick: {},
        blitz: {},
        onlineRegular: {},
        onlineQuick: {},
        onlineBlitz: {}
      },
      lastRatedEvent: {},
      state: elements[25].split(' ').last,
      gender: elements[26].split(" ").last,
      expirationDate: elements[27].split(" ").last,
      lastChangeDate: elements[28].split(" ").last,
    }

    order = [:regular, :quick, :blitz, :onlineRegular, :onlineQuick, :onlineBlitz]
    (10..15).each do |i|
      rating = elements[i]

      response[:ratings][order[i-10]] = rating

      if rating.include? "Unrated"
        response[:ratings][order[i-10]] = {
          elo: nil,
          games: 0,
          lastPlayed: nil
        }
      else
        response[:ratings][order[i-10]] = {
          elo: rating.split('Rating').last.split("(").first.to_i,
          games: rating.split('Based on')[1].to_i,
          lastPlayed: rating.split(')')[1].split(' ').last
        }
      end
    end

    # regex this: Last Rated Event: 201604238532 ARLINGTON CLASSICS ACADEMY Rated on 2016-04-23
    # into: ["Last Rated Event:", "201604238532", "ARLINGTON CLASSICS ACADEMY", "Rated on", "2016-04-23"]
    last_rated = elements[16].split(/(Last Rated Event: )(\d+)(.*)(Rated on )(\d+-\d+-\d+)/).delete_if { |e| e.blank? }

    response[:lastRatedEvent] = {
      eventId: last_rated[1],
      name: last_rated[2].strip,
      ratedOn: last_rated[4],
    }

    json_response response
  end
end
