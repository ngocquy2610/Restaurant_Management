class CreatePaymentMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_methods do |t|
      t.string :name
      t.integer :code
      t.boolean :active

      t.timestamps
    end
  end
end
