class AddStripeFieldsToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :stripe_checkout_session_id, :string
    add_column :payments, :stripe_payment_intent_id, :string
    add_index :payments, :stripe_checkout_session_id, unique: true
    add_index :payments, :stripe_payment_intent_id, unique: true
  end
end
