require "test_helper"

class TableNumberAutofillRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:one)
    @admin.update!(role: :admin, status: true)
    sign_in @admin
  end

  test "new table form renders auto-fill wiring" do
    get new_table_url
    assert_response :success

    body = response.body
    assert_includes body, "data-table-wizard-areas-value="
    assert_includes body, "data-table-wizard-table-types-value="
    assert_includes body, "data-table-wizard-area-tables-value="
    assert_includes body, "data-table-wizard-creating-value=\"true\""
    assert_includes body, "data-table-wizard-target=\"tableNumberField\""
    # The field should be read-only on a brand-new record.
    assert_includes body, "readonly=\"readonly\""
  end

  test "generating a new table persists an auto-filled unique table_number" do
    area = areas(:one)          # "First Floor" => "F"
    tt = TableType.create!(type: "VIP", price_add_on: 50)

    assert_difference("Table.count", 1) do
      post tables_url, params: {
        table: {
          area_id: area.id, table_type_id: tt.id,
          capacity: 4, status: :available, shape: :square,
          pos_x: 10, pos_y: 10, rotation: 0, width: 80, height: 60,
          table_number: ""
        }
      }
    end

    created = Table.last
    assert_equal "FFV1", created.table_number
  end
end
