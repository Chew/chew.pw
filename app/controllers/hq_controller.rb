class HqController < ApplicationController
  include Response
  before_action :index
  def index
    @user = get_user(session[:hq_online_token]) unless session[:hq_online_token].nil?
    redirect_to "/hq/signin" if session[:hq_online_token].nil? && !request.path.include?('signin') && !request.path.include?('question') && !request.path.include?('random') && !request.path.include?('endpoints')
  end

  def question
    ques = HqQuestion.order(Arel.sql('RAND()')).first

    output = JSON.parse('{"region":null,"question":{"question":null,"choice1":null,"choice2":null,"choice3":null,"correct":null},"choices":{"picked1":null,"picked2":null,"picked3":null},"game":{"q#":null,"time":null,"prize":null,"winners":null,"cashwon":null}}')

    output['region'] = ques.region
    output['question']['question'] = ques.question
    output['question']['choice1'] = ques.option1
    output['question']['choice2'] = ques.option2
    output['question']['choice3'] = ques.option3
    output['question']['correct'] = ques.correct
    output['choices']['picked1'] = ques.picked1
    output['choices']['picked2'] = ques.picked2
    output['choices']['picked3'] = ques.picked3
    output['game']['q#'] = ques.ques_num
    output['game']['time'] = ques.time
    output['game']['prize'] = ques.prize
    output['game']['winners'] = ques.winners
    output['game']['cashwon'] = (ques.prize.to_i / ques.winners.to_f).round(2)

    json_response(output.as_json, 200)
  end

  def get_user(key)
    get_data('users/me', key)
  end

  def get_data(endpoint, key)
    JSON.parse(RestClient.get("https://api-quiz.hype.space/#{endpoint}",
                              Authorization: key,
                              'x-hq-client': 'iOS/1.3.27 b121',
                              'Content-Type': :json))
  end

  def friends
    key = session[:hq_online_token]

    @friends = get_data('friends', key)
    @requests = get_data('friends/requests', key)
    @incoming = get_data('friends/requests/incoming', key)
    @contacts = get_data('contacts/players', key)
    @non_contacts = get_data('contacts/non-players', key)

    @any_in = @incoming['count'].positive?
    @any_out = @requests['count'].positive?

    @realcontacts = @contacts['data']
    @realcontacts.each do |e|
      @realcontacts.delete(e) if @realcontacts.map { |f| f['user']['username'] == e['user']['username'] }.count(true) > 1
    end
  end

  def signinhandle
    params['country'] = "1" if params['country'].nil?

    phone = "+#{params['country']}#{params['phone']}"

    requestparams = {
      'method' => params['method'],
      'phone' => phone
    }.to_json

    bob = RestClient.post('https://api-quiz.hype.space/verifications',
                          requestparams,
                          'x-hq-client': 'iOS/1.3.19 b107',
                          'Content-Type': :json)

    j = JSON.parse(bob)

    @verid = j['verificationId']
  end

  def signinconclude
    requestparams = {
      'code' => params['code']
    }.to_json

    bob = RestClient.post("https://api-quiz.hype.space/verifications/#{params['verificationId']}",
                          requestparams,
                          'x-hq-client': 'iOS/1.3.19 b107',
                          'Content-Type': :json,)


    broke = false

    begin
      j = JSON.parse(bob)['auth']

      code = j['authToken']
      user = j['username']
      userid = j['userId']
      session[:hq_online_token] = "Bearer #{code}"
      session[:hq_online_id] = userid
    rescue StandardError
      broke = true
    end

    redirect_to "/hq"
  end

  def logout
    session[:hq_online_token] = nil
    session[:hq_online_id] = nil

    redirect_to "/hq/signin"
  end
end
