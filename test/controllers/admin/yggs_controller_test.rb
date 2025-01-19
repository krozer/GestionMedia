require "test_helper"

class Admin::YggsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_yggs_index_url
    assert_response :success
  end
end
