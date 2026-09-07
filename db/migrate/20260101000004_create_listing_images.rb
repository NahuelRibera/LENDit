class CreateListingImages < ActiveRecord::Migration[7.1]
  def change
    create_table :listing_images do |t|
      t.references :listing, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.boolean :is_primary, null: false, default: false

      t.timestamps
    end

    add_index :listing_images, [:listing_id, :position]
    add_index :listing_images, :listing_id, unique: true, where: "is_primary",
      name: "index_listing_images_on_listing_id_when_primary"
  end
end
