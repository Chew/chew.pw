require "test_helper"

class SolitaireControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get solitaire_index_url
    assert_response :success
  end
end
