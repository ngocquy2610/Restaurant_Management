module ReservationsHelper
  # Presentation metadata for each Reservation#status. `dot` is the bullet colour
  # used on chips, `chip` the soft badge background, and `text` the label colour.
  RESERVATION_STATUS_META = {
    "pending"    => { label: "Pending",    dot: "bg-amber-500",  text: "text-amber-700",  chip: "bg-amber-100" },
    "approved"   => { label: "Approved",   dot: "bg-green-500",  text: "text-green-700",  chip: "bg-green-100" },
    "rejected"   => { label: "Rejected",   dot: "bg-red-500",    text: "text-red-700",    chip: "bg-red-100" },
    "checked_in" => { label: "Checked in", dot: "bg-teal-500",   text: "text-teal-700",   chip: "bg-teal-100" },
    "cancelled"  => { label: "Cancelled",  dot: "bg-gray-400",   text: "text-gray-600",   chip: "bg-gray-100" },
    "completed"  => { label: "Completed",  dot: "bg-slate-400",  text: "text-slate-600",  chip: "bg-slate-100" }
  }.freeze

  def reservation_status_meta(status)
    RESERVATION_STATUS_META.fetch(status.to_s, RESERVATION_STATUS_META["pending"])
  end

  def reservation_status_label(status)
    reservation_status_meta(status)[:label]
  end

  def reservation_status_dot_class(status)
    reservation_status_meta(status)[:dot]
  end

  def reservation_status_chip_class(status)
    reservation_status_meta(status)[:chip]
  end

  # Contextual quick-action buttons a staff member can take for a given status.
  # Each entry is { label:, status:, classes:, confirm: }. Returning an empty array
  # (terminal statuses like rejected/cancelled/completed) hides all buttons.
  RESERVATION_TRANSITIONS = {
    "pending" => [
      { label: "Approve", status: :approved,   confirm: "Approve this reservation?",
        classes: "bg-green-600 text-white hover:bg-green-700" },
      { label: "Reject",  status: :rejected,   confirm: "Reject this reservation? The table will be freed.",
        classes: "border border-red-200 bg-red-50 text-red-700 hover:bg-red-100" }
    ],
    "approved" => [
      { label: "Check in", status: :checked_in, confirm: "Check this guest in? The table becomes occupied.",
        classes: "bg-teal-600 text-white hover:bg-teal-700" },
      { label: "Cancel",   status: :cancelled,  confirm: "Cancel this reservation? The table will be freed.",
        classes: "border border-gray-200 bg-white text-gray-700 hover:bg-gray-50" }
    ],
    "checked_in" => [
      { label: "Complete", status: :completed, confirm: "Complete this reservation? The table becomes available.",
        classes: "bg-slate-600 text-white hover:bg-slate-700" },
      { label: "Cancel",   status: :cancelled, confirm: "Cancel this reservation? The table becomes available.",
        classes: "border border-gray-200 bg-white text-gray-700 hover:bg-gray-50" }
    ]
  }.freeze

  def reservation_actions(reservation)
    RESERVATION_TRANSITIONS.fetch(reservation.status.to_s, [])
  end
end
