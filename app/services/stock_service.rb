module StockService
  class Error < StandardError; end
  class InsufficientStock < Error; end # custom

  class << self
    def apply_transaction(ingredient:, transaction_type:, quantity:, user: nil,
                          reason: nil, reference: nil, strict: true)
      type  = transaction_type.to_sym
      delta = signed_delta(type, quantity)
      raise Error, "quantity must not be zero" if delta.zero?

      ActiveRecord::Base.transaction do
        record = Ingredient.lock.find(ingredient.id)
        before = record.current_quantity.to_d
        after  = before + delta

        if after.negative?
          raise InsufficientStock, "#{record.name} just has #{before} left" if strict
          after = 0.to_d
        end

        recorded = after - before
        tx = StockTransaction.create!(
          ingredient: record, user: user, transaction_type: type,
          quantity: type == :adjustment ? recorded : recorded.abs,
          quantity_before: before, quantity_after: after,
          reason: reason, reference: reference
        )
        record.update!(current_quantity: after)
        sync_restock_task!(record)
        tx
      end
    end

    def restock(ingredient:, quantity:, user: nil, reason: nil, reference: nil)
      apply_transaction(ingredient:, transaction_type: :stock_in, quantity:,
                        user:, reason: reason || "Restock", reference:)
    end

    def waste(ingredient:, quantity:, user: nil, reason: nil, reference: nil)
      apply_transaction(ingredient:, transaction_type: :waste, quantity:,
                        user:, reason:, reference:)
    end

    def adjust(ingredient:, new_quantity:, user: nil, reason: nil)
      ActiveRecord::Base.transaction do
        current = Ingredient.lock.find(ingredient.id).current_quantity.to_d
        delta   = new_quantity.to_d - current
        return nil if delta.zero?
        apply_transaction(ingredient:, transaction_type: :adjustment, quantity: delta,
                          user:, reason: reason || "Stock count adjustment")
      end
    end

    def consume_order_item!(order_item, user: nil)
      return if order_item.cancelled?
      reference = "order_item:#{order_item.id}"
      return if StockTransaction.exists?(reference: reference, transaction_type: :stock_out)

      ActiveRecord::Base.transaction do
        order_item.consumption_recipe_items.each do |recipe_item|
          next if recipe_item.ingredient.blank?
          apply_transaction(
            ingredient: recipe_item.ingredient,
            transaction_type: :stock_out,
            quantity: recipe_item.quantity_required.to_d * order_item.quantity.to_i,
            user: user,
            reason: "Auto-deduct: #{order_item.food&.name} x#{order_item.quantity} (order ##{order_item.order_id})",
            reference: reference,
            strict: true
          )
        end
      end
    end

    def consume_order!(order, user: nil)
      order.order_items.reject(&:cancelled?).each { |item| consume_order_item!(item, user: user) }
    end

    def restore_order_item!(order_item, user: nil)
      reference = "order_item:#{order_item.id}"
      restore_ref = "#{reference}:restore"

      return if StockTransaction.exists?(reference: restore_ref)

      StockTransaction.where(reference: reference, transaction_type: :stock_out)
                      .includes(:ingredient).find_each do |tx|
        apply_transaction(ingredient: tx.ingredient, transaction_type: :stock_in,
                          quantity: tx.quantity, user: user,
                          reason: "Restore: item ##{order_item.id} cancelled",
                          reference: restore_ref)
      end
    end

    def sync_restock_task!(ingredient)
      return unless ingredient.low_stock? || ingredient.out_of_stock?
      return if RestockTask.open.exists?(ingredient_id: ingredient.id)

      task = RestockTask.create!(
        ingredient: ingredient,
        quantity:   ingredient.suggested_reorder_quantity,
        source:     :auto,
        status:     :pending
      )
      Notification.notify_role(
        %i[inventory_manager admin],
        title: "Restock needed",
        body: "#{ingredient.name} is #{ingredient.status.humanize.downcase} (#{ingredient.current_quantity.to_f} #{ingredient.unit}).",
        redirect_url: Rails.application.routes.url_helpers.inventory_restock_task_path(task)
      )
    end

    private

    def signed_delta(type, quantity)
      qty = quantity.to_d
      case type
      when :stock_in            then  qty.abs
      when :stock_out, :waste   then -qty.abs
      when :adjustment          then  qty
      else raise Error, "unknown transaction_type: #{type}"
      end
    end
  end
end
