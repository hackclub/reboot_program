class AddShopItemToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :shop_orders, :shop_item, null: false, foreign_key: true
  end
end
