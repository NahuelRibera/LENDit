class CreateListings < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pg_trgm"

    create_table :listings do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.references :category, null: false, foreign_key: { on_delete: :restrict }
      t.string :title, null: false
      t.text :description, null: false
      t.integer :price_cents, null: false
      t.string :condition, null: false
      t.string :status, null: false, default: "draft"
      t.string :city, null: false
      t.virtual :search_vector, type: :tsvector, stored: true,
        as: "setweight(to_tsvector('simple', coalesce(title, '')), 'A') || setweight(to_tsvector('simple', coalesce(description, '')), 'B')"

      t.timestamps
    end

    add_index :listings, :status
    add_index :listings, :search_vector, using: :gin
    add_index :listings, :title, opclass: :gin_trgm_ops, using: :gin, name: "index_listings_on_title_trgm"

    add_check_constraint :listings, "price_cents > 0", name: "listings_price_cents_positive"
    add_check_constraint :listings, "condition IN ('new','like_new','good','fair')", name: "listings_condition_check"
    add_check_constraint :listings, "status IN ('draft','published','paused','archived')", name: "listings_status_check"
  end
end
