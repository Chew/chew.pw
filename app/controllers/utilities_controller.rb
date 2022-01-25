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

  def wordle_solve
    confirmed = params['confirmed'].map(&:downcase).delete_if { |x| x.blank? }
    required = (params['required'].downcase.split('') + confirmed).uniq.delete_if { |x| x.blank? }
    can = (params['can'].downcase.split('') + required).uniq.delete_if { |x| x.blank? }
    pattern = params['confirmed'].map {|e| e.length == 1 ? e : "*" }

    possible = LA + TA
    likely = []

    possible.each do |word|
      letters = word.split('')
      no = false
      required.each do |letter|
        no = true unless letters.include?(letter)
      end

      if no
        # puts "Not #{word} due to missing required letters: #{required.join(', ')}"
        next
      end

      letters.each do |letter|
        # word must include only letters from "can"
        no = true unless can.include?(letter)
      end

      if no
        puts "Not #{word} due to missing can letters: #{can.join(', ')}"
        next
      end

      pattern.each_with_index do |star, i|
        next if star == "*"

        no = true unless letters[i] == star
      end

      if no
        puts "Not #{word} due to missing pattern: #{pattern.join(', ')}"
        next
      end

      likely.push word
      puts "Possible: #{word}"
    end

    @info = {
      confirmed: confirmed,
      required: required,
      can: can,
      pattern: pattern,
    }

    @wordles = likely
  end
end
