require "test_helper"

class PreordersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @preorder = preorders(:one)
  end

  test "should get index" do
    get preorders_url
    assert_response :success
  end

  test "should get new" do
    get new_preorder_url
    assert_response :success
  end

  test "should create preorder" do
    assert_difference("Preorder.count") do
      post preorders_url, params: { preorder: {} }
    end

    assert_redirected_to preorder_url(Preorder.last)
  end

  test "should show preorder" do
    get preorder_url(@preorder)
    assert_response :success
  end

  test "should get edit" do
    get edit_preorder_url(@preorder)
    assert_response :success
  end

  test "should update preorder" do
    patch preorder_url(@preorder), params: { preorder: {} }
    assert_redirected_to preorder_url(@preorder)
  end

  test "should destroy preorder" do
    assert_difference("Preorder.count", -1) do
      delete preorder_url(@preorder)
    end

    assert_redirected_to preorders_url
  end
end
