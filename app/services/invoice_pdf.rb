require "prawn"
require "prawn/table"

class InvoicePdf < Prawn::Document
  # Prefer bundled fonts; fall back to system DejaVu (supports ₫ and Vietnamese).
  BUNDLED_DIR = Rails.root.join("app/assets/fonts")
  SYSTEM_DIR = Pathname.new("/usr/share/fonts/truetype/dejavu")

  def initialize(order:, payment:)
    super(page_size: "A4", page_layout: :portrait, margin: 40)

    @order = order
    @payment = payment

    setup_fonts
  end

  def generate
    add_header
    add_order_information
    add_items_table
    add_totals
    add_footer

    render
  end

  private

  def setup_fonts
    raise "Invoice fonts missing: #{missing_fonts.join(', ')}" if missing_fonts.any?

    font_families.update(
      "InvoiceSans" => {
        normal: font_dir.join("DejaVuSans.ttf").to_s,
        bold: font_dir.join("DejaVuSans-Bold.ttf").to_s
      }
    )

    font "InvoiceSans"
  end

  def font_dir
    bundled_fonts_present? ? BUNDLED_DIR : SYSTEM_DIR
  end

  def missing_fonts
    %w[DejaVuSans.ttf DejaVuSans-Bold.ttf].reject { |f| font_dir.join(f).exist? }
  end

  def bundled_fonts_present?
    %w[DejaVuSans.ttf DejaVuSans-Bold.ttf].all? { |f| BUNDLED_DIR.join(f).exist? }
  end

  def add_header
    text "Lumière Dining", size: 20, style: :bold, align: :center
    move_down 3
    text "RESTAURANT INVOICE  •  HÓA ĐƠN THANH TOÁN",
         size: 12, style: :bold, align: :center
    move_down 12
    stroke_horizontal_rule
    move_down 14
  end

  def add_order_information
    data = [
      ["Invoice no.", "Payment ##{@payment.id} (Order ##{@order.id})"],
      ["Customer", customer_name],
      ["Table", table_label],
      ["Waiter", waiter_name],
      ["Issued at", issued_at_label],
      ["Paid at", paid_at_label],
      ["Payment method", payment_method_name],
      ["Status", @payment.status.to_s.humanize]
    ]

    table(data, width: bounds.width) do
      cells.borders = []
      cells.padding = 4
      columns(0).font_style = :bold
      columns(0).width = 130
    end

    move_down 18
  end

  def add_items_table
    text "Order Items", size: 14, style: :bold
    move_down 8

    table(item_rows, header: true, width: bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = "EEEEEE"
      cells.padding = 6
      columns(0).width = 250
      columns(1).align = :center
      columns(2..3).align = :right
    end

    move_down 8

    if @order.table_price.to_d.positive?
      text "Includes table fee: #{format_currency(@order.table_price)}",
           size: 9, align: :right
    end

    move_down 18
  end

  def item_rows
    rows = [["Item", "Qty", "Unit Price", "Amount"]]

    @order.order_items.includes(:food, :food_variant).each do |item|
      quantity = item.quantity.to_i
      unit_price = item.unit_price.to_d

      rows << [
        item_name(item),
        quantity.to_s,
        format_currency(unit_price),
        format_currency(unit_price * quantity)
      ]
    end

    rows
  end

  def add_totals
    # Snapshot frozen on the payment at creation/confirm time.
    subtotal = @payment.subtotal.to_d
    discount = @payment.discount_amount.to_d
    total = @payment.total_amount.to_d

    total_rows = [
      ["Subtotal", format_currency(subtotal)],
      [discount_label, "-#{format_currency(discount)}"],
      ["Total (USD)", format_usd(total)],
      ["Total (VND)", format_currency(@payment.total_amount_vnd)]
    ]

    table(total_rows, width: 280, position: :right) do
      cells.borders = []
      cells.padding = 5
      columns(0).font_style = :bold
      columns(1).align = :right
      row(2).font_style = :bold
      row(3).font_style = :bold
      row(3).size = 13
    end

    move_down 14

    return if @payment.total_amount == @order.total_price

    text "Note: order total has changed since this payment was created. " \
         "Create a new payment for the updated total.",
         size: 9, align: :right
  end

  def add_footer
    move_down 28
    stroke_horizontal_rule
    move_down 10
    text "Thank you for dining with us!", align: :center, size: 10
    text "Cảm ơn quý khách đã sử dụng dịch vụ.", align: :center, size: 10
  end

  # -------------------------
  # Data helpers
  # -------------------------

  def customer_name
    @order.customer&.full_name.presence || "Guest"
  end

  def table_label
    @order.table&.table_number.presence || "—"
  end

  def waiter_name
    @order.waiter&.full_name.presence || "—"
  end

  def payment_method_name
    @payment.payment_method&.name.presence || "N/A"
  end

  def issued_at_label
    @payment.created_at&.strftime("%d/%m/%Y %H:%M") || "—"
  end

  def paid_at_label
    @payment.paid_at&.strftime("%d/%m/%Y %H:%M") || "—"
  end

  def discount_label
    pct = @order.membership_discount_percent
    pct.positive? ? "Discount (#{pct}% member)" : "Discount"
  end

  def item_name(item)
    base = item.food&.name || "Unknown dish"
    variant = item.food_variant&.name
    variant.present? ? "#{base} (#{variant})" : base
  end

  def format_currency(amount)
    delimited = ActiveSupport::NumberHelper.number_to_delimited(amount.to_d.round(0).to_i)
    "#{delimited} ₫"
  end

  def format_usd(amount)
    "$#{format('%.2f', amount.to_d)}"
  end
end