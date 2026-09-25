module CustomerQueueManager
  class << self
    def enqueue_walk_in!(attrs, staff:)
      CustomerQueue.create!(attrs.merge(user: staff, status: :waiting))
    end

    def seat!(queue_entry, table)
      CustomerQueue.transaction do
        queue_entry.hold_table!(table)
        Order.create!(table: table, status: :inserve)
      end
    end

    def assign_next_available!(table)
      return unless table.available?
      guest = CustomerQueue.waiting.first
      seat!(guest, table) if guest
    end
  end
end
