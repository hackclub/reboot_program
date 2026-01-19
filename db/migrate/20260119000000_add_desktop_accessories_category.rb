class AddDesktopAccessoriesCategory < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Desktop Accessories',
        'wireless_microphone',
        'Wireless Microphone - Generic',
        180,
        18,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0A9M0KQYD8/71zjmpyficl._ac_sl1500_-removebg-preview.png?pub_secret=d51d8d4182',
        'active',
        'This provides a $18 HCB card grant to spend on Desktop Accessories',
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
    execute "DELETE FROM shop_items WHERE category = 'Desktop Accessories' AND variant_key = 'wireless_microphone'"
  end
end
