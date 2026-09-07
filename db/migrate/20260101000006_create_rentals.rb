class CreateRentals < ActiveRecord::Migration[7.1]
  def change
    enable_extension "btree_gist"

    create_table :rentals do |t|
      t.references :listing, null: false, foreign_key: { on_delete: :restrict }
      t.references :borrower, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :lender, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: "pending"
      t.integer :daily_price_cents, null: false
      t.integer :total_price_cents, null: false
      t.text :cancellation_reason
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.datetime :requested_at, null: false
      t.datetime :accepted_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :declined_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :rentals, :status

    add_check_constraint :rentals, "end_date >= start_date", name: "rentals_date_order_check"
    add_check_constraint :rentals, "borrower_id <> lender_id", name: "rentals_borrower_not_lender_check"
    add_check_constraint :rentals, "status IN ('pending','accepted','active','completed','declined','cancelled')",
      name: "rentals_status_check"

    # The actual concurrency guarantee: no two accepted/active rentals for
    # the same listing can have overlapping (inclusive) date ranges. This
    # holds even under concurrent requests — Postgres enforces it at the
    # storage layer, not in application code.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE rentals
          ADD CONSTRAINT rentals_no_overlapping_accepted_active
          EXCLUDE USING gist (
            listing_id WITH =,
            daterange(start_date, end_date, '[]') WITH &&
          )
          WHERE (status IN ('accepted', 'active'))
        SQL
      end

      dir.down do
        execute "ALTER TABLE rentals DROP CONSTRAINT rentals_no_overlapping_accepted_active"
      end
    end
  end
end
