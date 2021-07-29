class ApiController < ApplicationController
  include Response
  skip_before_action :verify_authenticity_token
  before_action :goodbye_token

  def goodbye_token
    form_authenticity_token = nil
  end

  def random_string
    many = params['length'].to_i || 25
    many = 1000 if many > 1000
    many = 2 if many < 2

    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten


    json_response({ "response": (0...many).map { o[rand(o.length)] }.join }, 200)
  end

  def url
    if params['url'].nil? || params['url'] !~ URI::DEFAULT_PARSER.make_regexp
      json_response({"error": "Missing or invalid 'url' parameter"}, 400)
      return
    end

    extensiontest = false

    extensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp']
    nourl = params['url'].downcase
    extensions.each do |e|
      extensiontest = true if nourl.end_with?(e)
    end

    unless extensiontest
      json_response({"error": "Invalid or unsupported file extension"}, 400)
      return
    end

    begin
      image = RestClient.get(params['url']).headers[:content_type].start_with? 'image'
    rescue SocketError, RestClient::Forbidden, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED
      json_response({"error": "Invalid url"}, 400)
      return
    end

    unless image
      json_response({"error": "URL isn't an image"}, 400)
      return
    end

    json_response({"status": "ok"}, 200)
  end

  def trbmb
    many = request.headers['amount'].to_i || 1
    many = 1000 if many > 1000
    many = 1 if many < 1
    words = TRBMB_WORDS

    words1 = words[0][13..-1].delete('"').split(',')

    words2 = words[2][13..-1].delete('"').split(',')

    output = []
    many.times do |e|
      output += ["That really #{words1.sample} my #{words2.sample}"]
    end

    @hey = output.as_json
    json_response(@hey)
  end

  def acronym
    acronym = params['acronym']
    acronym = acronym.downcase
    letters = acronym.split("")
    phrase = ''
    words = {}
    ACRONYM_LIST[1..26].each do |letter|
      sep = letter.split(": ")
      let = sep[0].gsub(" ", "").gsub('"', "")
      wds = sep[1].gsub('"', "")
      words[let] = wds.split(',')
    end
    letters.each do |i|
      if words[i].nil?
        phrase += ''
      else
        phrase += words[i].sample
        phrase += ' '
      end
    end

    phrase.chomp!(' ')

    json_response({ phrase: phrase }, 200)
  end

  def hq
    name = params['username']

    key = Rails.application.credentials.trbmb[:hq_key]

    require 'json'

    findid = RestClient.get('https://api-quiz.hype.space/users',
                            params: { q: name },
                            Authorization: key,
                            'x-hq-device': 'iPhone10,4',
                            'x-hq-stk': 'MQ==',
                            'x-hq-deviceclass': 'phone',
                            'x-hq-timezone': 'America/Chicago',
                            'user-agent': 'HQ-iOS/147 CFNetwork/1085.4 Darwin/19.0.0',
                            'x-hq-country': 'us',
                            'x-hq-lang': 'en',
                            'x-hq-client': 'iOS/1.4.15 b146',
                            'Content-Type': :json)

    id = JSON.parse(findid)['data'][0]['userId']

    data = RestClient.get("https://api-quiz.hype.space/users/#{id}",
                          Authorization: key,
                          'x-hq-device': 'iPhone10,4',
                          'x-hq-stk': 'MQ==',
                          'x-hq-deviceclass': 'phone',
                          'x-hq-timezone': 'America/Chicago',
                          'user-agent': 'HQ-iOS/147 CFNetwork/1085.4 Darwin/19.0.0',
                          'x-hq-country': 'us',
                          'x-hq-lang': 'en',
                          'x-hq-client': 'iOS/1.4.15 b146',
                          'Content-Type': :json)

    data = JSON.parse(data)

    @hey = {
      'username' => data['username'],
      'wins' => data['winCount'].to_s,
      'games' => data['gamesPlayed'].to_s,
      'total' => data['leaderboard']['total']
    }.as_json
    json_response(@hey)
  end

  def chewspeak
    input = params['input']
    if input.nil?
      json_response({ "error": "please provide a 'input' parameter" }, 400)
      return
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

    json_response({ "input": params['input'], "output": output.join(' ') }, 200)
  end

  def spigot_drama
    combinations = SPIGOT_DRAMA['combinations']
    sentences = SPIGOT_DRAMA['sentences']

    base64 = {}

    index = 0
    sentence = sentences.sample
    base64['sentence'] = sentences.index{|e| e == sentence}
    while sentence.include? "["
      combinations.each do |key, value|
        placeholder = "[#{key}]"
        replacement = combinations[key].sample
        i = combinations[key].index{|e| e == replacement}
        if sentence.include? placeholder
          sentence = sentence.sub(placeholder, replacement)
          if base64[key].nil?
            base64[key] = [i]
          else
            base64[key].push i
          end
        end
      end
    end

    json_response({"response": sentence, "permalink": "https://drama.essentialsx.net/#{Base64.encode64(base64.to_json.to_s).gsub("\n", "")}"}, 200)
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
