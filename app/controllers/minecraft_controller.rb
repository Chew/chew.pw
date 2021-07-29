class MinecraftController < ApplicationController
  include Response
  include Magick

  def analyzelog
    if 1 == 2
      captcha = {
        "secret": Rails.application.credentials.minecraft[:hcaptcha_secret],
        "response": params['h-captcha-response']
      }
      r = JSON.parse(RestClient.post('https://hcaptcha.com/siteverify', captcha.as_json, 'Content-Type': :json))
      unless r['success']
        flash[:modal_message] = 'Invalid Captcha Response, try again, robot.'
        redirect_to '/meme/submit'
        return
      end
    end

    #Aws.config.update(
    #  region: 'us-east-2',
    #  credentials: Aws::Credentials.new(Rails.application.credentials.dig(:aws, :access_key_id), Rails.application.credentials.dig(:aws, :secret_access_key))
    #)

    #s3 = Aws::S3::Client.new
    type = request.parameters['log'].content_type
    extension = File.extname(request.parameters['log'].original_filename)
    mime = FileMagic.new(FileMagic::MAGIC_MIME).file(request.parameters['log'].tempfile.path)
    unless mime.include? "text/plain"
      flash[:modal_message] = 'This is not a valid log file!'
      redirect_to '/mc/log'
      return
    end
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    string = (0...10).map { o[rand(o.length)] }.join
    name = string + extension.to_s
    #obj = s3.put_object(
    #  bucket: 'cdn.memerator.me',
    #  body: request.parameters['log'].open,
    #  acl: 'public-read',
    #  key: name,
    #  content_type: type
    #)
    #url = "https://cdn.memerator.me/#{name}"

    @paper_versions = Rails.cache.fetch("paper/version", expires_in: 1.day) do
      JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/paper"))
    end

    @type = ""
    @mc_ver = ""
    @version = ""
    @plugins = []
    @could_not_load = []
    @could_not_enable = []
    @could_enable = []
    @stack_traces = []
    @error = []
    @warn = []
    @hang = []
    @prev = ""
    @normal_line = false
    File.readlines(request.parameters['log']).each do |line|
      line = line.chomp
      if line.include?("Starting minecraft server version")
        @mc_ver = line.split("Starting minecraft server version ").last
        @type = 'latest.log'
      end
      if line.include?("Minecraft Crash Report")
        @type = "crash"
      end

      case @type
      when 'latest.log'
        handlelatestlogline(line)
      when 'crash'
        redirect_to "/mc/log"
        flash[:modal_message] = "We're sorry, we currently do not support this type of log, or a valid type wasn't detected!"
        return
      end
    end

    if @type == ""
      redirect_to "/mc/log"
      flash[:modal_message] = "We're sorry, we currently do not support this type of log, or a valid type wasn't detected!"
      return
    end

    @version_message = nil
    if @version.include?('Paper') && @paper_versions['versions'].include?(@mc_ver)
      latest = JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/paper/versions/#{@mc_ver}"))['builds'].last.to_i
      current = @version.split('git-Paper-').last.split(" ").first.to_i
      if current == latest
        @version_message = "Your Paper build is up to date!"
      else
        @version_message = "Your Paper build is outdated by #{latest-current} versions! Yours: #{current}. Latest: #{latest}."
      end
    end

    if @mc_ver == "" && @version == ""
      flash[:modal_message] = 'Invalid log file!'
      redirect_to '/mc/log'
    end
  end

  def handlelatestlogline(line)
    if line.include?("]:")
      @normal_line = true
    else
      @normal_line = false
    end
    start_trace = false
    @version = line.split("This server is running ").last if line.include?("This server is running")
    if line.include?("Could not load 'plugins/") && line.include?(".jar")
      @could_not_load.push line.split("Could not load 'plugins/").last.split("' in folder 'plugins'").first
    end
    if line.include?("Error occurred while enabling") && line.include?("(Is it up to date?)")
      @could_not_enable.push line.split("Error occurred while enabling ").last.split(" (Is it up to date?)").first
    end
    if line.include? "DO NOT REPORT THIS TO PAPER - THIS IS NOT A BUG OR A CRASH"
      @hang.push line
    end
    return if line.include?("Paper Watchdog Thread")
    if line.include? "/ERROR]"
      @error.push line
      start_trace = true
    end
    if line.include? "/WARN]"
      @warn.push line
      start_trace = true
    end
    if line.include? "Enabling"
      plugin = line.split("/INFO]: [").last.split("]").first
      check = line.split("Enabling ").last.split(" ").first
      if plugin == check
        @could_enable.push line.split("Enabling ").last
      end
    end
    if line.include? "Disabling"
      @could_enable.delete(line.split("Enabling ").last)
    end
    if start_trace && @normal_line
      if @prev.include?("ERROR")
        @stack_traces.push [@error.last, line]
      else
        @stack_traces.push [@warn.last, line]
      end
    end
    unless @normal_line
      @stack_traces.last.push line
    end
    @prev = line
  end

  def jars
    @paper = Rails.cache.fetch("paper/version", expires_in: 1.day) do
      JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/paper"))
    end
  end

  def get_build
    version = "Unknown!"
    case params['type']
    when 'velocity'
      version = JSON.parse(RestClient.get("https://versions.velocitypowered.com/version/latest"))['version']
    when 'bungeecord'
      version = "#" + JSON.parse(RestClient.get("https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/api/json"))['id']
    when 'paper', 'waterfall', 'travertine'
      mc_ver = params['version']
      if mc_ver.nil?
        mc_ver = JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/#{params['type']}"))['versions'].last
      end
      version = "#" + JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/#{params['type']}/versions/#{mc_ver}"))['builds'].last.to_s
      if params['type'] == 'paper'
        params['type'] = "paper/#{mc_ver}"
      end
    when 'geyser'
      version = "#" + JSON.parse(RestClient.get("https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/lastSuccessfulBuild/api/json"))['id']
    when 'floodgate'
      version = "#" + JSON.parse(RestClient.get("https://ci.opencollab.dev/job/GeyserMC/job/Floodgate/job/master/lastSuccessfulBuild/api/json"))['id']
    else
      'Unknown!'
    end

    respond_to do |format|
      @type = params['type']
      @build = version
      format.html { redirect_to "/mc/jars" }
      format.json { head :no_content }
      format.js { render partial: 'build' }
    end
  end

  def download_jar
    if params['type'] == "velocity"
      latest = JSON.parse(RestClient.get("https://versions.velocitypowered.com/version/latest"))['version']
      redirect_to "https://versions.velocitypowered.com/download/#{latest}.jar"
      return
    end
    version = params['version']
    if version.nil?
      version = JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/#{params['type']}"))['versions'].last
    end
    begin
      build = JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/#{params['type']}/versions/#{version}"))['builds'].last
    rescue RestClient::NotFound
      flash[:modal] = "This version does not exist!"
      redirect_to "/mc/jars"
      return
    end
    if build.nil?
      flash[:modal] = "No builds for this version exist!"
      redirect_to "/mc/jars"
      return
    end
    download = JSON.parse(RestClient.get("https://papermc.io/api/v2/projects/#{params['type']}/versions/#{version}/builds/#{build}"))['downloads']['application']['name']

    redirect_to "https://papermc.io/api/v2/projects/#{params['type']}/versions/#{version}/builds/#{build}/downloads/#{download}"
  end

  def favicon_handle
    original = Magick::Image.read(request.parameters['picture'].tempfile.path).first
    target = Magick::Image.new(64, 64) do |e|
      e.background_color = "Transparent"
    end
    case params['type']
    when 'resize'
      original.resize!(64, 64)
    when 'resize_to_fill'
      original.resize_to_fill!(64, 64)
    when 'resize_to_fit'
      original.resize_to_fit!(64, 64)
    else
      # type code here
      original.scale!(64, 64)
    end
    newimg = Tempfile.new(["server-icon", ".png"])
    target.composite(original, Magick::CenterGravity, Magick::CopyCompositeOp).write(newimg.path)

    @image = newimg
    flash[:path] = @image.path
  end
end
