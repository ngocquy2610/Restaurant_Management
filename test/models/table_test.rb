require "test_helper"

class TableTest < ActiveSupport::TestCase
  # Build a table that satisfies all Presence/Dimension requirements except the
  # capacity/shape rules under test.
  def build_table(shape:, capacity:)
    Table.new(
      area: areas(:one),
      table_type: table_types(:one),
      table_number: "TEST#{SecureRandom.hex(4)}",
      shape: shape,
      capacity: capacity,
      status: :available,
      pos_x: 10,
      pos_y: 10,
      rotation: 0,
      radius: shape.to_s == "round" ? 40 : nil,
      width: shape.to_s == "round" ? nil : 80,
      height: shape.to_s == "round" ? nil : 60
    )
  end

  test "valid capacity/shape combinations are accepted" do
    {
      square: [2, 4],
      round: [4, 6],
      rectangle: [6, 8, 10]
    }.each do |shape, capacities|
      capacities.each do |capacity|
        assert build_table(shape: shape, capacity: capacity).valid?,
               "#{shape} should accept capacity #{capacity}"
      end
    end
  end

  test "capacities outside 2, 4, 6, 8, 10 are rejected" do
    [1, 3, 5, 12].each do |capacity|
      table = build_table(shape: :square, capacity: capacity)
      assert_not table.valid?, "capacity #{capacity} should be rejected"
      assert table.errors[:capacity].any?, "expected a capacity error for #{capacity}"
    end
  end

  test "capacity must match the table shape" do
    assert build_table(shape: :square, capacity: 6).invalid?, "square cannot seat 6"
    assert build_table(shape: :round, capacity: 10).invalid?, "round cannot seat 10"
    assert build_table(shape: :rectangle, capacity: 4).invalid?, "rectangle cannot seat 4"

    table = build_table(shape: :square, capacity: 6)
    assert_not table.valid?
    assert table.errors[:capacity].any?
  end

  test "allowed dropdown capacities are 2, 4, 6, 8, 10" do
    assert_equal [2, 4, 6, 8, 10], Table::ALLOWED_CAPACITIES
  end

  test "table_number auto-generates from area + table type when blank" do
    area = areas(:one) # "First Floor" -> first char "F"
    table_type = TableType.create!(type: "Standard", price_add_on: 0)

    table = Table.new(
      area: area,
      table_type: table_type,
      shape: :square,
      capacity: 4,
      status: :available,
      pos_x: 10, pos_y: 10, rotation: 0, width: 80, height: 60
    )

    assert table.save
    assert_equal "FFS1", table.table_number
  end

  test "table_number increments to the lowest unused index within the area" do
    area = areas(:one)
    table_type = TableType.create!(type: "Standard", price_add_on: 0)

    Table.create!(
      area: area, table_type: table_type, table_number: "FFS1",
      shape: :square, capacity: 4, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 80, height: 60
    )

    table = Table.new(
      area: area, table_type: table_type,
      shape: :square, capacity: 4, status: :available,
      pos_x: 10, pos_y: 10, rotation: 0, width: 80, height: 60
    )

    assert table.save
    assert_equal "FFS2", table.table_number
  end

  test "table_type char differs the generated prefix for the same area" do
    area = areas(:one)
    standard = TableType.create!(type: "Standard", price_add_on: 0)
    vip = TableType.create!(type: "VIP", price_add_on: 50)

    std = Table.new(area: area, table_type: standard, shape: :square, capacity: 4,
                    status: :available, pos_x: 0, pos_y: 0, rotation: 0, width: 80, height: 60)
    v = Table.new(area: area, table_type: vip, shape: :square, capacity: 4,
                  status: :available, pos_x: 0, pos_y: 0, rotation: 0, width: 80, height: 60)

    assert std.save
    assert v.save
    assert_equal "FFS1", std.table_number
    assert_equal "FFV1", v.table_number
  end

  test "explicit table_number is preserved when provided" do
    area = areas(:one)
    table_type = TableType.create!(type: "Standard", price_add_on: 0)

    table = Table.new(
      area: area, table_type: table_type, table_number: "A99",
      shape: :square, capacity: 4, status: :available,
      pos_x: 10, pos_y: 10, rotation: 0, width: 80, height: 60
    )

    assert table.save
    assert_equal "A99", table.table_number
  end
end

