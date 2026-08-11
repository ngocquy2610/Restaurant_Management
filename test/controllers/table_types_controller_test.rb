require "test_helper"

class TableTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @table_type = table_types(:one)
  end

  test "should get index" do
    get table_types_url
    assert_response :success
  end

  test "should get new" do
    get new_table_type_url
    assert_response :success
  end

  test "should create table_type" do
    assert_difference("TableType.count") do
      post table_types_url, params: { table_type: {} }
    end

    assert_redirected_to table_type_url(TableType.last)
  end

  test "should show table_type" do
    get table_type_url(@table_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_table_type_url(@table_type)
    assert_response :success
  end

  test "should update table_type" do
    patch table_type_url(@table_type), params: { table_type: {} }
    assert_redirected_to table_type_url(@table_type)
  end

  test "should destroy table_type" do
    assert_difference("TableType.count", -1) do
      delete table_type_url(@table_type)
    end

    assert_redirected_to table_types_url
  end
end
