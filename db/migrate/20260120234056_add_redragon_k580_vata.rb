class AddRedragonK580Vata < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Keyboard',
        'redragon_k580_vata',
        'Redragon K580 VATA',
        700,
        70,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0A9XNG5AR1/71jpclbdpdl._ac_sl1500_-removebg-preview.png?pub_secret=fd6004eed1',
        'active',
        'This provides a $70 HCB card grant to spend on a Keyboard',
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
    execute "DELETE FROM shop_items WHERE category = 'Keyboard' AND variant_key = 'redragon_k580_vata'"
  end
end
