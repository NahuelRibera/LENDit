class CreateRecentlyViewedListings < ActiveRecord::Migration[7.1]
  def change
    create_table :recently_viewed_listings do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :listing, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :viewed_at, null: false

      t.timestamps
    end

    add_index :recently_viewed_listings, [:user_id, :listing_id], unique: true
  end
end
