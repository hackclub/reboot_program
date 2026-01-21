class AddTpLinkNanoAc600Image < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.squish
      UPDATE shop_items
      SET image_url = 'https://files.slack.com/files-pri/T09V59WQY1E-F0A9X3TH6CE/51oi6lrnicl._ac_sl1276_-removebg-preview.png?pub_secret=b6eefcf2ee'
      WHERE category = 'Desktop Accessories' AND variant_key = 'tp_link_nano_ac600'
    SQL
  end

  def down
    execute <<-SQL.squish
      UPDATE shop_items
      SET image_url = NULL
      WHERE category = 'Desktop Accessories' AND variant_key = 'tp_link_nano_ac600'
    SQL
  end
end
