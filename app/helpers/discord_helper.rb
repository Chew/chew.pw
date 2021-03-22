module DiscordHelper
  def verified_image(height = 20)
    ActionController::Base.helpers.image_tag 'https://cdn.discordapp.com/emojis/753433397933899826.png', height: "#{height}px", alt: 'This server is verified!', tooltip: 'This server is verified!', style: 'margin-bottom: 5px', lazy: false
  end

  def created_at(id)
    ms = (id.to_i >> 22) + 1_420_070_400_000
    created = Time.at(ms / 1000.0)
    created.strftime "%D %r"
  end
end
