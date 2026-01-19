class AddCorsairT3Rush < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
      VALUES (
        'Chair',
        'corsair_t3_rush',
        'Corsair T3 Rush',
        3500,
        350,
        'https://files.slack.com/files-pri/T09V59WQY1E-F0AA047NXMF/t3-rush-fabric-gaming-chair-_2023_---charcoal-0.webp-removebg-preview.png?pub_secret=8f603e7161',
        'active',
        'This provides a $350 HCB card grant to spend on Chair',
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
    execute "DELETE FROM shop_items WHERE category = 'Chair' AND variant_key = 'corsair_t3_rush'"
  end
end
