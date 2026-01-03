# Adds profile fields for user sync to Airtable.
class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :birthday, :date
    add_column :users, :balance, :decimal, precision: 10, scale: 2, default: 0
  end
end
