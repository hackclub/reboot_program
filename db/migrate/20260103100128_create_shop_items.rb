class CreateShopItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_items do |t|
      t.string :name
      t.decimal :cost
      t.string :status
      t.string :description
      t.string :link
      t.decimal :price
      t.string :image_url
      t.timestamps
    end
  end
end
