require "test_helper"

class YggMoviesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ygg_movies_index_url
    assert_response :success
  end
end
