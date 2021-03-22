require 'test_helper'

class TrbmbControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get trbmb_index_url
    assert_response :success
  end

end
