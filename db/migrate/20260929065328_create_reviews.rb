class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :reservation, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :review_type, null: false, default: 0
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_index :reviews, :review_type

    add_index :reviews, :reservation_id, unique: true, where: "review_type = 0",
              name: "index_reviews_unique_meal_per_reservation"

    add_index :reviews, :user_id, unique: true, where: "review_type = 1",
              name: "index_reviews_unique_restaurant_per_customer"

    add_check_constraint :reviews, "rating BETWEEN 1 AND 5", name: "reviews_rating_range"
  end
end
