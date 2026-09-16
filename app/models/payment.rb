class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :payment_method
  belongs_to :processed_by,
           class_name: "User",
           optional: true
  
  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2,
    refunded: 3
  }
end
