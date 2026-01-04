class AddSyncedAtToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :synced_at, :datetime
  end
end
