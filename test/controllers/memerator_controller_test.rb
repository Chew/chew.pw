require 'test_helper'

class MemeratorControllerTest < ActionDispatch::IntegrationTest
  test "should get memeviewer" do
    get memerator_memeviewer_url
    assert_response :success
  end

end
