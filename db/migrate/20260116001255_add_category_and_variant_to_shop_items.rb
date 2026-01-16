class AddCategoryAndVariantToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :category, :string
    add_column :shop_items, :variant_key, :string
    add_column :shop_items, :grant_amount, :decimal, precision: 10, scale: 2

    add_index :shop_items, :category
    add_index :shop_items, :variant_key
    add_index :shop_items, [:category, :variant_key], unique: true
  end
end
