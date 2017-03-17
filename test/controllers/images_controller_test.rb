require 'test_helper'

class ImagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get images_index_url
    assert_response :success
  end

  test "should get compare" do
    get images_compare_url
    assert_response :success
  end

end
