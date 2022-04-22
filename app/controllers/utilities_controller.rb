class UtilitiesController < ApplicationController
  def vaccine
    @states = [
      "Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut","Delaware","District of Columbia","Florida","Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"
    ]
    @territories = [
      "American Samoa","Guam","Marshall Islands","Micronesia","Northern Marianas","Palau","Puerto Rico","U.S. Virgin Islands"
    ]

    @data = Rails.cache.fetch("vaccine/info", expires_in: 1.day) do
      # Get data from bloomberg
      res = RestClient.get("http://api.scraperapi.com?api_key=#{Rails.application.credentials.utilities[:scraper_api]}&url=https://www.bloomberg.com/graphics/covid-vaccine-tracker-global-distribution/")

      info = JSON.parse res.body.split('dvz-data-cave').last.split('dvz-content').first.split("\n")[1]

      {
        updated: Time.now,
        info: info
      }.as_json
    end
  end

  def strippedhtml
    @response = Nokogiri::HTML.parse(params['input']).text
  end

  def wordle
    session["wordle_confirmed"] = ["", "", "", "", ""] if session["wordle_confirmed"].nil? || session["wordle_confirmed"].length != 5
    session["wordle_required"] = ["", "", "", "", ""] if session["wordle_required"].nil? || session["wordle_required"].length != 5
  end

  def wordle_solve
    confirmed = params['confirmed'].map(&:downcase).delete_if { |x| x.blank? }
    required_map = params['required'].map(&:downcase)
    required = (required_map.join('').downcase.split('') + confirmed).uniq.delete_if { |x| x.blank? }
    alphabet = ('a'..'z').to_a
    if params['can'].to_s.length.positive?
      can = (params['can'].downcase.split('') + required).uniq.delete_if { |x| x.blank? }
    else
      can = alphabet - params['cant'].downcase.split('')
    end
    can += confirmed
    can += required
    can.uniq!
    puts "Can #{can}"
    pattern = params['confirmed'].map(&:downcase).map {|e| e.length == 1 ? e : "*" }

    %w[confirmed required can cant].each do |param|
      session["wordle_#{param}"] = params[param].is_a?(Array) ? params[param].map(&:downcase) : params[param].downcase
    end

    possible = LA + TA
    likely = []

    possible.each do |word|
      letters = word.split('')
      no = false
      required.each do |letter|
        no = true unless letters.include?(letter)
      end

      next if no

      letters.each do |letter|
        # word must include only letters from "can"
        no = true unless can.include?(letter)
      end

      next if no

      pattern.each_with_index do |star, i|
        next if star == "*"

        no = true unless letters[i] == star
      end

      # Check the required map to make sure the letters are in the right spot
      letters.each_with_index do |letter, i|
        next if required_map[i] == ""

        if required_map[i].include?(letter)
          no = true
          puts "#{letter} is in the wrong spot in the word #{word}"
        end
      end

      next if no

      likely.push word
    end

    @info = {
      confirmed: confirmed,
      required: required,
      can: can,
      pattern: pattern,
    }

    @wordles = likely.sort
  end
end
