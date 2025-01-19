require "test_helper"

class TmdbMoviesControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get tmdb_movies_search_url
    assert_response :success
  end
end
