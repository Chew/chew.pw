module RobloxHelper
  def has_badge?(user, badge_name)
    user.each do |bad|
      return true if bad['Item']['Name'] == badge_name
    end
    
    false
  end
end
