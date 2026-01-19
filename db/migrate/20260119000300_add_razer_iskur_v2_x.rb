class AddRazerIskurV2X < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Chair',
        'razer_iskur_v2_x',
        'Razer Iskur V2 X',
        3000,
        300,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0A9QP4LY5S/https---medias-p1.phoenix.razer.com-sys-master-phoenix-images-container-h77-hba-9883860271134-iskur-v2-x-gray-500x500-v3-removebg-preview.png?pub_secret=fc1c527c98',
        'active',
        'This provides a $300 HCB card grant to spend on Chair',
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
    execute "DELETE FROM shop_items WHERE category = 'Chair' AND variant_key = 'razer_iskur_v2_x'"
  end
end
