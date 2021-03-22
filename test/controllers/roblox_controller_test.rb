require 'test_helper'

class RobloxControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get roblox_index_url
    assert_response :success
  end

end
