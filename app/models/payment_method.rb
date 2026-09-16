class PaymentMethod < ApplicationRecord
  has_many :payments, dependent: :restrict_with_error

  enum :code, {
    cash: 0,
    card: 1,
    qr: 2
  }
end
