require 'test_helper'

class CookiesincControllerTest < ActionDispatch::IntegrationTest
  test "should get battlemobs" do
    get cookiesinc_battlemobs_url
    assert_response :success
  end

end
