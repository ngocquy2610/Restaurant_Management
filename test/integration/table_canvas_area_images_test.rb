require "test_helper"

class TableCanvasAreaImagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

  setup do
    @admin = User.create!(
      full_name: "Admin User",
      email: "canvas-admin@example.com",
      phone: "5558881234",
      password: "password",
      role: :admin
    )
    sign_in @admin
  end

  test "new table page passes each area's floor-map image to the step two canvas" do
    with_image = Area.create!(name: "Terrace", area_type: :outdoor, floor_level: 2)
    with_image.image.attach(
      io: StringIO.new(Base64.decode64(PNG_BASE64)),
      filename: "terrace.png",
      content_type: "image/png"
    )
    no_image = Area.create!(name: "Cellar", area_type: :indoor, floor_level: -1)

    get new_table_path
    assert_response :success

    images = canvas_area_images(response.body)
    assert_match %r{\A/rails/active_storage}, images[with_image.id.to_s]
    assert_equal "terrace.png", File.basename(images[with_image.id.to_s])
    assert_nil images[no_image.id.to_s]
  end

  private

  def canvas_area_images(body)
    raw = body[/data-table-canvas-area-images-value="([^"]+)"/, 1]
    JSON.parse(CGI.unescapeHTML(raw))
  end
end
