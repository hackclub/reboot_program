class AddGtplayerGamingChair < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Chair',
        'gtplayer_gaming_chair',
        'GTPLAYER Gaming Chair',
        1300,
        130,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0A9QMS927N/71ml_a04pfl._ac_sl1500_-removebg-preview.png?pub_secret=61a2e5547b',
        'active',
        'This provides a $130 HCB card grant to spend on Chair',
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
    execute "DELETE FROM shop_items WHERE category = 'Chair' AND variant_key = 'gtplayer_gaming_chair'"
  end
end
