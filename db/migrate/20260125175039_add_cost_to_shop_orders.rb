class AddCostToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :cost, :decimal, precision: 10, scale: 2, default: 0
  end
end
