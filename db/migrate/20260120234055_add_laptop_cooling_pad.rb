class AddLaptopCoolingPad < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Desktop Accessories',
        'laptop_cooling_pad',
        'Laptop Cooling Pad',
        130,
        13,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0A9SPRSUPM/71ytmupqxyl._ac_sl1500_-removebg-preview.png?pub_secret=8dc60a7d52',
        'active',
        'This provides a $13 HCB card grant to spend on Desktop Accessories',
        NOW(),
        NOW()
      )
      ON CONFLICT (category, variant_key) DO UPDATE SET
        name = EXCLUDED.name,
        cost = EXCLUDED.cost,
        grant_amount = EXCLUDED.grant_amount,
        image_url = EXCLUDED.image_url,
        status = EXCLUDED.status,
        description = EXCLUDED.description,
        updated_at = NOW()
    SQL
  end

  def down
    execute "DELETE FROM shop_items WHERE category = 'Desktop Accessories' AND variant_key = 'laptop_cooling_pad'"
  end
end
