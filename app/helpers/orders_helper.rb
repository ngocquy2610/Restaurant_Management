module OrdersHelper
  # Presentation metadata for Order#status and OrderItem#status.
  ORDER_STATUS_META = {
    "preorder"  => { label: "Pre-order", chip: "bg-amber-100", text: "text-amber-700",  dot: "bg-amber-500" },
    "inserve"   => { label: "In service", chip: "bg-blue-100", text: "text-blue-700",   dot: "bg-blue-500" },
    "completed" => { label: "Completed", chip: "bg-green-100", text: "text-green-700",  dot: "bg-green-500" }
  }.freeze

  ORDER_ITEM_STATUS_META = {
    "pending"   => { label: "Pending",   chip: "bg-amber-100", text: "text-amber-700",  dot: "bg-amber-500" },
    "accepted"  => { label: "Accepted",  chip: "bg-blue-100",  text: "text-blue-700",   dot: "bg-blue-500" },
    "preparing" => { label: "Preparing", chip: "bg-indigo-100", text: "text-indigo-700", dot: "bg-indigo-500" },
    "ready"     => { label: "Ready",     chip: "bg-teal-100",  text: "text-teal-700",   dot: "bg-teal-500" },
    "served"    => { label: "Served",    chip: "bg-green-100", text: "text-green-700",  dot: "bg-green-500" },
    "cancelled" => { label: "Cancelled", chip: "bg-red-100",   text: "text-red-700",    dot: "bg-red-500" }
  }.freeze

  ORDER_ITEM_TRANSITIONS = {
    "pending" => %i[accepted cancelled].freeze,
    "accepted" => %i[preparing cancelled].freeze,
    "preparing" => %i[ready cancelled].freeze,
    "ready" => %i[served].freeze,
    "served" => [].freeze,
    "cancelled" => [].freeze
  }.freeze

  def order_status_badge(status)
    meta = ORDER_STATUS_META.fetch(status.to_s, ORDER_STATUS_META["inserve"])
    badge_tag(meta)
  end

  def order_item_status_badge(status)
    meta = ORDER_ITEM_STATUS_META.fetch(status.to_s, ORDER_ITEM_STATUS_META["pending"])
    badge_tag(meta)
  end

  def order_item_next_statuses(status)
    ORDER_ITEM_TRANSITIONS.fetch(status.to_s, [])
  end

  private

  def badge_tag(meta)
    content_tag(:span, meta[:label],
      class: "inline-flex items-center gap-2 rounded-full #{meta[:chip]} px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] #{meta[:text]}")
  end
end
