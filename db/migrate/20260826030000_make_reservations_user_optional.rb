class MakeReservationsUserOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :reservations, :user_id, true
  end
end