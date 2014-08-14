require 'test_helper'

class HttpRequestsControllerTest < ActionController::TestCase
  test "should get get_json" do
    get :get_json
    assert_response :success
  end

  test "should get post_url_encoded" do
    get :post_url_encoded
    assert_response :success
  end

  test "should get post_multi_part" do
    get :post_multi_part
    assert_response :success
  end

end
