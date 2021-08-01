module DiscordHelper
  def verified_image(height = 20, partnered = false)
    ActionController::Base.helpers.image_tag 'https://cdn.discordapp.com/emojis/753433397933899826.png', height: "#{height}px", alt: 'This server is verified!',
                                             title: "This server is #{partnered ? "verified and partnered" : "verified"}!", 'data-bs-toggle': 'tooltip',
                                             style: 'margin-bottom: 5px', lazy: false
  end

  def partnered_icon(height = 20)
    ActionController::Base.helpers.image_tag 'https://cdn.discordapp.com/emojis/753433398139289701.png', height: "#{height}px", alt: 'This server is partnered!',
                                             title: 'This server is partnered!', 'data-bs-toggle': 'tooltip',
                                             style: 'margin-bottom: 5px', lazy: false
  end

  # Generate a status icon for this server as it would appear in the client.
  # If verified, show verified. If partnered, show partnered. If both, show verified.
  # @param features [Array<String>] The features this server has
  # @param height [Integer] The height in pixels
  def status_icon(features, height = 20)
    if features.include?("VERIFIED") and features.include?("PARTNERED")
      verified_image height, true
    elsif features.include? "VERIFIED"
      verified_image(height)
    elsif features.include? "PARTNERED"
      partnered_icon height
    end
  end

  def created_at(id)
    ms = (id.to_i >> 22) + 1_420_070_400_000
    created = Time.at(ms / 1000.0)
    created.strftime "%D %r"
  end

  def friendly_permissions(bits)
    perms = Discordrb::Permissions.new bits
    perms.defined_permissions.map { |e| e.to_s.titleize }.join(', ')
  end
end
