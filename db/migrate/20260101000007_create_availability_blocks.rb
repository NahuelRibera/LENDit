class CreateAvailabilityBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_blocks do |t|
      t.references :listing, null: false, foreign_key: { on_delete: :cascade }
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :reason

      t.timestamps
    end

    add_check_constraint :availability_blocks, "end_date >= start_date", name: "availability_blocks_date_order_check"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE availability_blocks
          ADD CONSTRAINT availability_blocks_no_overlap
          EXCLUDE USING gist (
            listing_id WITH =,
            daterange(start_date, end_date, '[]') WITH &&
          )
        SQL
      end

      dir.down do
        execute "ALTER TABLE availability_blocks DROP CONSTRAINT availability_blocks_no_overlap"
      end
    end
  end
end
