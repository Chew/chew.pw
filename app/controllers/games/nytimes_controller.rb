class Games::NytimesController < GamesController
  def index
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

  def wordle_answer
    # Check to see if current eastern time is between midnight and 11:59 pm Thursday, December 8th, 2022
    @walkout = Time.now.in_time_zone('Eastern Time (US & Canada)').between?(Time.new(2022, 12, 8, 0, 0, 0, "-05:00"), Time.new(2022, 12, 8, 23, 59, 59, "-05:00"))

    @word = JSON.parse(RestClient.get("https://www.nytimes.com/svc/wordle/v2/#{params[:date]}.json"))
  end

  def connections
    # get today's date in YYYY-MM-DD format

    if params[:date]
      @data = JSON.parse(RestClient.get("https://www.nytimes.com/svc/connections/v1/#{params[:date]}.json"))
    end
  end

  def strands
    # get today's date in YYYY-MM-DD format

    if params[:date]
      @data = JSON.parse(RestClient.get("https://www.nytimes.com/svc/strands/v2/#{params[:date]}.json", 'User-Agent': DUMMY_USER_AGENT))
    end
  end
end
