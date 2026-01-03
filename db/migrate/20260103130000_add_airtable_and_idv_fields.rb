# frozen_string_literal: true

# Migration to add Airtable sync IDs and IDV verification fields.
# Idempotent: checks for existing columns before adding.
class AddAirtableAndIdvFields < ActiveRecord::Migration[8.0]
  def change
    # Add airtable_id to shop_items
    unless column_exists?(:shop_items, :airtable_id)
      add_column :shop_items, :airtable_id, :string
      add_index :shop_items, :airtable_id, unique: true
    end

    # Add airtable_id to shop_orders
    unless column_exists?(:shop_orders, :airtable_id)
      add_column :shop_orders, :airtable_id, :string
      add_index :shop_orders, :airtable_id, unique: true
    end

    # Add IDV fields to users
    unless column_exists?(:users, :idv_verified)
      add_column :users, :idv_verified, :boolean, default: false
    end

    unless column_exists?(:users, :idv_verified_at)
      add_column :users, :idv_verified_at, :datetime
    end
  end
end
