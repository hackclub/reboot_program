class CreateShopOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_orders do |t|
      t.string :name
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
