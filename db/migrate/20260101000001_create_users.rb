class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"

    create_table :users do |t|
      t.citext :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.text :bio
      t.string :city
      t.integer :ratings_count, null: false, default: 0
      t.decimal :ratings_avg, precision: 3, scale: 2, null: false, default: "0.0"

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
