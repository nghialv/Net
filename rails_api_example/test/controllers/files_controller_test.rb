require 'test_helper'

class FilesControllerTest < ActionController::TestCase
  test "should get download_image" do
    get :download_image
    assert_response :success
  end

  test "should get download_pdf" do
    get :download_pdf
    assert_response :success
  end

  test "should get download_zip" do
    get :download_zip
    assert_response :success
  end

  test "should get upload_image" do
    get :upload_image
    assert_response :success
  end

  test "should get upload_pdf" do
    get :upload_pdf
    assert_response :success
  end

  test "should get upload_zip" do
    get :upload_zip
    assert_response :success
  end

end
