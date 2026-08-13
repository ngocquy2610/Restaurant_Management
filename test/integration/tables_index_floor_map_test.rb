require "test_helper"

class TablesIndexFloorMapTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # A 1x1 red PNG (used so ActiveStorage accepts the file_format validation).
  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

  setup do
    @admin = User.create!(
      full_name: "Admin User",
      email: "img-admin@example.com",
      phone: "5557654321",
      password: "password",
      role: :admin
    )
    sign_in @admin
  end

  test "index embeds the area image in the floor-map payload and keeps 1200x700" do
    area = Area.create!(name: "Garden", area_type: :outdoor, floor_level: 3)
    area.image.attach(
      io: StringIO.new(Base64.decode64(PNG_BASE64)),
      filename: "garden.png",
      content_type: "image/png"
    )

    get tables_path(area_id: area.id)
    assert_response :success

    payload = floor_map_area_payload(response.body)
    assert_equal 1200, payload["width"]
    assert_equal 700, payload["height"]
    assert_equal area.image.filename.to_s, File.basename(payload["image"])
    assert_match %r{\A/rails/active_storage}, payload["image"]
  end

  test "index omits the image key when the area has no attached image" do
    Area.create!(name: "Dining", area_type: :indoor, floor_level: 1)

    get tables_path
    assert_response :success
    assert_nil floor_map_area_payload(response.body)["image"]
  end

  private

  # Extract the floor-map area payload from the (HTML-escaped) data attribute.
  def floor_map_area_payload(body)
    raw = body[/data-floor-map-area-value="([^"]+)"/, 1]
    JSON.parse(CGI.unescapeHTML(raw))
  end
end
