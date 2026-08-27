class AddDetailToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :reservation_date, :date
    add_column :reservations, :reservation_time, :time
  end
end
