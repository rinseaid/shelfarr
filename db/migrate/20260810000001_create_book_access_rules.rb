# frozen_string_literal: true

class CreateBookAccessRules < ActiveRecord::Migration[8.1]
  def change
    create_table :book_access_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.references :granted_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end
    add_index :book_access_rules, [ :user_id, :book_id ], unique: true
  end
end
