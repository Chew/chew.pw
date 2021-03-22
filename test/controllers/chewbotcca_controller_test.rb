require 'test_helper'

class ChewbotccaControllerTest < ActionDispatch::IntegrationTest
  test "should get commands" do
    get chewbotcca_commands_url
    assert_response :success
  end

end
