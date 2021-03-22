require 'test_helper'

class HqbotControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get hqbot_index_url
    assert_response :success
  end

end
