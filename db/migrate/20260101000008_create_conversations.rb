class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :listing, null: false, foreign_key: { on_delete: :restrict }
      t.references :user_one, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :user_two, null: false, foreign_key: { to_table: :users, on_delete: :cascade }

      t.timestamps
    end

    add_check_constraint :conversations, "user_one_id < user_two_id", name: "conversations_user_order_check"
    add_index :conversations, [:listing_id, :user_one_id, :user_two_id], unique: true,
      name: "index_conversations_on_listing_and_users"

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :sender, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.text :body, null: false

      t.timestamps
    end

    add_index :messages, [:conversation_id, :created_at]

    create_table :conversation_reads do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :conversation_reads, [:conversation_id, :user_id], unique: true
  end
end
