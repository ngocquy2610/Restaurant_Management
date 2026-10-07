module InventoryHelper
  LOW_STOCK_REQUEST_URGENCY_META = {
    "low"    => { label: "Low",    chip: "bg-slate-100", text: "text-slate-600" },
    "normal" => { label: "Normal", chip: "bg-blue-100",  text: "text-blue-700" },
    "high"   => { label: "High",   chip: "bg-red-100",   text: "text-red-700" }
  }.freeze

  INGREDIENT_STATUS_META = {
    "in_stock"     => { label: "In stock",     chip: "bg-green-100", text: "text-green-700" },
    "low_stock"    => { label: "Low stock",    chip: "bg-amber-100", text: "text-amber-700" },
    "out_of_stock" => { label: "Out of stock", chip: "bg-red-100",   text: "text-red-700" }
  }.freeze

  LOW_STOCK_REQUEST_STATUS_META = {
    "pending"   => { label: "Pending",   chip: "bg-amber-100", text: "text-amber-700" },
    "approved"  => { label: "Approved",  chip: "bg-green-100", text: "text-green-700" },
    "rejected"  => { label: "Rejected",  chip: "bg-red-100",   text: "text-red-700" },
    "completed" => { label: "Completed", chip: "bg-slate-100", text: "text-slate-600" }
  }.freeze

  WASTE_REPORT_STATUS_META = {
    "pending"  => { label: "Pending",  chip: "bg-amber-100", text: "text-amber-700" },
    "approved" => { label: "Approved", chip: "bg-green-100", text: "text-green-700" },
    "rejected" => { label: "Rejected", chip: "bg-red-100",   text: "text-red-700" }
  }.freeze

  RESTOCK_TASK_STATUS_META = {
    "pending"     => { label: "Pending",     chip: "bg-amber-100", text: "text-amber-700" },
    "in_progress" => { label: "In progress", chip: "bg-blue-100",  text: "text-blue-700" },
    "completed"   => { label: "Completed",   chip: "bg-green-100", text: "text-green-700" },
    "cancelled"   => { label: "Cancelled",   chip: "bg-gray-100",  text: "text-gray-600" }
  }.freeze

  RESTOCK_TASK_SOURCE_META = {
    "auto"    => { label: "Auto",            chip: "bg-slate-100", text: "text-slate-600" },
    "request" => { label: "Kitchen request", chip: "bg-amber-100", text: "text-amber-700" },
    "waste"   => { label: "Waste report",    chip: "bg-red-100",   text: "text-red-700" }
  }.freeze

  STOCK_TRANSACTION_TYPE_META = {
    "stock_in"   => { label: "Stock in",   chip: "bg-green-100", text: "text-green-700" },
    "stock_out"  => { label: "Stock out",  chip: "bg-blue-100",  text: "text-blue-700" },
    "adjustment" => { label: "Adjustment", chip: "bg-amber-100", text: "text-amber-700" },
    "waste"      => { label: "Waste",      chip: "bg-red-100",   text: "text-red-700" }
  }.freeze

  def ingredient_status_badge(status) = inventory_badge(INGREDIENT_STATUS_META, status)
  def low_stock_request_status_badge(status) = inventory_badge(LOW_STOCK_REQUEST_STATUS_META, status)
  def waste_report_status_badge(status) = inventory_badge(WASTE_REPORT_STATUS_META, status)
  def restock_task_status_badge(status) = inventory_badge(RESTOCK_TASK_STATUS_META, status)
  def restock_task_source_badge(source) = inventory_badge(RESTOCK_TASK_SOURCE_META, source)
  def stock_transaction_type_badge(type) = inventory_badge(STOCK_TRANSACTION_TYPE_META, type)
  def low_stock_request_urgency_badge(urgency) = inventory_badge(LOW_STOCK_REQUEST_URGENCY_META, urgency)

  # Shared sidebar styling so every inventory/kitchen page stays visually identical.
  def sidebar_nav_class(path)
    base   = "flex items-center gap-3 rounded-md px-3 py-3 text-[1.05rem] font-medium"
    active = "bg-[#e9d4d0] text-[#5a1a1b] shadow-inner"
    idle   = "text-[#5c4543] hover:bg-[#f1e0dc]"

    "#{base} #{current_page?(path) ? active : idle}"
  end

  def inventory_quantity(value, unit = nil)
    formatted = number_with_precision(value.to_d, precision: 2, strip_insignificant_zeros: true)
    unit.present? ? "#{formatted} #{unit}" : formatted
  end

  def inventory_time(value)
    value ? value.strftime("%d %b %Y · %H:%M") : "—"
  end

  private

  def inventory_badge(meta_map, key)
    meta = meta_map.fetch(key.to_s, { label: key.to_s.humanize, chip: "bg-gray-100", text: "text-gray-600" })

    content_tag(:span, meta[:label],
      class: "inline-flex items-center rounded-full #{meta[:chip]} px-2.5 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.14em] #{meta[:text]}")
  end
end
