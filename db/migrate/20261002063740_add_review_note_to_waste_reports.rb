class AddReviewNoteToWasteReports < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_reports, :review_note, :text
  end
end
