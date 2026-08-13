require "test_helper"

class AreasControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(
      full_name: "Admin User",
      email: "area-admin@example.com",
      phone: "5551234567",
      password: "password",
      role: :admin
    )
    sign_in @admin
  end

  test "should get new area page with the creation form" do
    get new_area_path
    assert_response :success

    assert_select "form" do
      assert_select "input[name='area[name]']"
      assert_select "select[name='area[area_type]']"
      assert_select "input[name='area[floor_level]']"
      assert_select "input[name='area[image]'][type='file']"
      assert_select "input[type='submit'][value='Create area']"
    end
  end

  test "should create area" do
    assert_difference("Area.count") do
      post areas_path, params: { area: { name: "Garden Terrace", area_type: :outdoor, floor_level: 3 } }
    end

    assert_redirected_to tables_path
  end

  test "should get edit area page with the update form" do
    area = Area.create!(name: "Terrace", area_type: :outdoor, floor_level: 2)

    get edit_area_path(area)
    assert_response :success

    assert_select "form" do
      assert_select "input[name='area[name]'][value='Terrace']"
      assert_select "select[name='area[area_type]']"
      assert_select "input[name='area[floor_level]'][value='2']"
      assert_select "input[name='area[image]'][type='file']"
      assert_select "input[type='submit'][value='Update area']"
    end
  end

  test "edit page previews an attached floor map image" do
    png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    area = Area.create!(name: "Terrace", area_type: :outdoor, floor_level: 2)
    area.image.attach(io: StringIO.new(Base64.decode64(png)), filename: "terrace.png", content_type: "image/png")

    get edit_area_path(area)
    assert_response :success
    assert_includes response.body, "Current floor map for Terrace"
  end

  test "should update area" do
    area = Area.create!(name: "Terrace", area_type: :outdoor, floor_level: 2)

    patch area_path(area), params: { area: { name: "Rooftop", area_type: :outdoor, floor_level: 3 } }

    assert_redirected_to tables_path
    area.reload
    assert_equal "Rooftop", area.name
    assert_equal 3, area.floor_level
  end
end
