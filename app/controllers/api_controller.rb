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

  def randombirb
    birb = RestClient.get("http://birb.proximy.st/")
    @id = birb.cookies['Id']
    @permalink = birb.cookies['Permalink']
    @image = Base64.encode64(birb.body)
  end

  def new_rory
    unless request.headers["Authorization"] == Rails.application.credentials.trbmb[:rory_key]
      json_response({}, 404)
      return
    end

    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    extension = params['rory'].split('.').last
    string = (0...8).map { o[rand(o.length)] }.join
    name = string + "." + extension.to_s

    data = {
      key: Rails.application.credentials.trbmb[:rory_image_key],
      image: params['rory'],
      name: name
    }

    imgbb = JSON.parse(RestClient.post("https://api.imgbb.com/1/upload",
                                       data.as_json,
                                       'Content-Type': :json))

    url = imgbb['data']['url'].gsub("i.ibb.co", "img.rory.cat")
    data = {
      url: url
    }
    RestClient.post("https://rory.cat/new", data.as_json, Authorization: Rails.application.credentials.trbmb[:rory_key], 'Content-Type': :json)
    json_response({success: true}, 201)
  end

  def get_faq
    unless request.headers["Authorization"] == Rails.application.credentials.trbmb[:mcpro_faq]
      json_response( { "success": false }, 401)
      return
    end

    json_response(McproFaq.search(params['search']), 200)
  end
end