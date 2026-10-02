class AddUrgencyAndReviewNoteToLowStockRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :low_stock_requests, :urgency, :integer, null: false, default: 0
    add_column :low_stock_requests, :review_note, :text
    add_index  :low_stock_requests, :urgency
  end
end
