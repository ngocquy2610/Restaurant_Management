# Reviews used to come in two flavours: a "meal" review per reservation and a
# "restaurant" review per customer. They are now a single restaurant review,
# one per customer, so existing rows are merged before the type is dropped.
class MergeMealReviewsIntoRestaurantReviews < ActiveRecord::Migration[8.1]
  def up
    return unless column_exists?(:reviews, :review_type)

    remove_index :reviews, name: :index_reviews_unique_meal_per_reservation
    remove_index :reviews, name: :index_reviews_on_review_type
    remove_index :reviews, name: :index_reviews_unique_restaurant_per_customer
    remove_index :reviews, name: :index_reviews_on_user_id

    merge_reviews_per_customer

    remove_column :reviews, :review_type

    add_index :reviews, :user_id, unique: true, name: :index_reviews_on_user_id
  end

  def down
    return if column_exists?(:reviews, :review_type)

    remove_index :reviews, name: :index_reviews_on_user_id

    add_column :reviews, :review_type, :integer, default: 0, null: false

    add_index :reviews, :review_type
    add_index :reviews, :reservation_id, unique: true,
              where: "(review_type = 0)", name: :index_reviews_unique_meal_per_reservation
    add_index :reviews, :user_id, unique: true,
              where: "(review_type = 1)", name: :index_reviews_unique_restaurant_per_customer
    add_index :reviews, :user_id, name: :index_reviews_on_user_id
  end

  private

  # Keep each customer's newest review, mix every non-blank comment into it
  # (oldest first), and delete the rest so the unique index on user_id can be
  # created. Reviews without a user_id are left untouched.
  def merge_reviews_per_customer
    rows = select_all(
      "SELECT id, user_id, comment FROM reviews WHERE user_id IS NOT NULL ORDER BY user_id, created_at, id"
    ).to_a

    rows.group_by { |row| row["user_id"] }.each_value do |group|
      next if group.one?

      keeper = group.last
      comments = group.filter_map { |row| row["comment"].to_s.strip.presence }.uniq
      merged_comment = comments.join("\n\n").first(1000)
      stale_ids = group.drop(1).map { |row| row["id"].to_i }

      execute(
        "UPDATE reviews SET comment = #{ActiveRecord::Base.connection.quote(merged_comment)} " \
        "WHERE id = #{keeper['id'].to_i}"
      )
      execute("DELETE FROM reviews WHERE id IN (#{stale_ids.join(', ')})")
    end
  end
end
