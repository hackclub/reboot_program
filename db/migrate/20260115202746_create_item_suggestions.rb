class CreateItemSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :item_suggestions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_name, null: false
      t.string :item_link, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :item_suggestions, :status
  end
end
