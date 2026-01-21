class AddTpLinkNanoAc600 < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, status, description, created_at, updated_at)
      VALUES (
        'Desktop Accessories',
        'tp_link_nano_ac600',
        'TP-Link Nano AC600',
        180,
        18,
        'active',
        'This provides a $18 HCB card grant to spend on Desktop Accessories',
        NOW(),
        NOW()
      )
      ON CONFLICT (category, variant_key) DO UPDATE SET
        name = EXCLUDED.name,
        cost = EXCLUDED.cost,
        grant_amount = EXCLUDED.grant_amount,
        status = EXCLUDED.status,
        description = EXCLUDED.description,
        updated_at = NOW()
    SQL
  end

  def down
    execute "DELETE FROM shop_items WHERE category = 'Desktop Accessories' AND variant_key = 'tp_link_nano_ac600'"
  end
end
