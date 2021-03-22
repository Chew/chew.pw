require 'test_helper'

class GeocachingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get geocaching_index_url
    assert_response :success
  end

end
