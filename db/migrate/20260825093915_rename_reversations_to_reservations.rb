class RenameReversationsToReservations < ActiveRecord::Migration[8.1]
  def change
    rename_table :reversations, :reservations
  end
end
