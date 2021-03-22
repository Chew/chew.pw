require 'test_helper'

class HqControllerTest < ActionDispatch::IntegrationTest
  test "should get question" do
    get hq_question_url
    assert_response :success
  end

end
