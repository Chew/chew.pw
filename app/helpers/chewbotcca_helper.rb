module ChewbotccaHelper
  def invite_link(permissions)
    "https://discord.com/api/oauth2/authorize?client_id=604362556668248095&permissions=#{permissions}&scope=bot%20applications.commands"
  end
end
