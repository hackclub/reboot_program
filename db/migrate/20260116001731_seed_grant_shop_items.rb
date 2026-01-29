class SeedGrantShopItems < ActiveRecord::Migration[8.0]
  def up
    grant_items = [
      { category: "Keyboard", variants: [
        { key: "standard", name: "Standard grant - Redragon K668", cost: 500, grant: 50,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7ER52G1Z/618a_b25mkl._ac_sl1500_-removebg-preview.png?pub_secret=1320d4d467" },
        { key: "aula_f75", name: "AULA F75", cost: 789, grant: 79,
          image_url: "" },
        { key: "quality", name: "Quality grant - YUNZII AL80", cost: 1100, grant: 110,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A75QDL9RV/1-1_ce938024-87eb-49c3-8c5d-b5cc0d707dba-removebg-preview.png?pub_secret=c90aae67c7" },
        { key: "advanced", name: "Advanced grant - Lemokey P1 HE", cost: 1700, grant: 170,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7F2PV2HH/lemokey-p1-he-wireless-custom-gaming-keyboard-black-aluminum-frame-gateron-double-rail-magnetic-nebula-switch-shine-through-double-shot-pbt-keycaps-version-removebg-preview.png?pub_secret=192f3a7612" },
        { key: "professional", name: "Professional grant - Logitech G715", cost: 2200, grant: 220,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7MF33W1G/g715-gallery-2-removebg-preview.png?pub_secret=097bb6bd73" }
      ] },
      { category: "Mouse", variants: [
        { key: "standard", name: "Standard grant - Logitech G305 Lightspeed", cost: 300, grant: 30,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A8FV4J6D6/51sg9blsmtl._ac_sl1500_-removebg-preview.png?pub_secret=74f57a6d05" },
        { key: "quality", name: "Quality grant - Razer DeathAdder", cost: 500, grant: 50,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A767XQ16K/51xly45csfl._ac_sl1500_-removebg-preview.png?pub_secret=9a90d6c299" },
        { key: "advanced", name: "Advanced grant - G309 LIGHTSPEED", cost: 1000, grant: 100,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A8G2W1SL8/g309-lightspeed-wireless-mouse-white-gallery-1-removebg-preview.png?pub_secret=6c9a8f14ef" },
        { key: "professional", name: "Professional grant - MX Master 4", cost: 1600, grant: 160,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A8G33U1C0/mx-master-4-black-top-angle-gallery-1-removebg-preview.png?pub_secret=ec87f2385a" }
      ] },
      { category: "Monitor", variants: [
        { key: "standard", name: "Standard grant", cost: 500, grant: 50,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A793DR88Z/10740609.png?pub_secret=edffb80446" },
        { key: "quality", name: "Quality grant - Dell 24 Monitor SE2425HM", cost: 1100, grant: 110,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7F6E19JP/71xzjnua6ol._ac_sl1500_-removebg-preview.png?pub_secret=34d59477ce" },
        { key: "advanced", name: "Advanced grant - ViewSonic VX3276-MHD", cost: 1700, grant: 180,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7R6G417W/71kwnok18dl._ac_sl1500_-removebg-preview.png?pub_secret=cb9559cf58" },
        { key: "professional", name: "Professional grant - SANSUI 32-Inch WQHD", cost: 2300, grant: 230,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7R7B1EHJ/71tgy5mzewl._ac_sl1500_-removebg-preview.png?pub_secret=3222c0235f" }
      ] },
      { category: "Headphones", variants: [
        { key: "razer_blackshark_v2_x", name: "Razer BlackShark V2 X", cost: 400, grant: 40,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0ABXT50XPW/51frjhb7xol._sl1001_-removebg-preview.png?pub_secret=92af7c9c64" },
        { key: "standard", name: "Standard grant - TOZO HT3", cost: 500, grant: 50,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7MSCHU9Y/61loj4pkq9l._ac_sl1500_-removebg-preview.png?pub_secret=4fb9286809" },
        { key: "quality", name: "Quality grant - Soundcore Life Q30", cost: 1100, grant: 110,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7MSWHNN6/a3028013_product_image_01_v1_c44d6360-d58c-4b7f-8bbd-badb130ac318_3838x.png-removebg-preview.png?pub_secret=21fa71aa8e" },
        { key: "professional", name: "Professional grant - AirPods Pro 3", cost: 2400, grant: 240,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7N00MX0S/61solmqssll._ac_sl1500_-removebg-preview.png?pub_secret=1a0a6173df" }
      ] },
      { category: "Webcam", variants: [
        { key: "standard", name: "Standard grant - EMEET 1080P", cost: 500, grant: 50,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7JHN68SZ/61z8ekkuicl._ac_sl1419_-removebg-preview.png?pub_secret=9c212fcd15" },
        { key: "quality", name: "Quality grant - Elgato Facecam MK.2", cost: 1400, grant: 140,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7N1ARELS/61j7cbovgwl._ac_sl1500_-removebg-preview.png?pub_secret=0c3a335e34" },
        { key: "professional", name: "Professional grant - Insta360 Link 2 + Tripod Bundle", cost: 2300, grant: 230,
          image_url: "https://files.slack.com/files-pri/T09V59WQY1E-F0A7FLAH1QT/2300_9fee1f64-961e-4081-8b3b-fab7d75f1d89.png-removebg-preview.png?pub_secret=fae045f047" }
      ] }
    ]

    grant_items.each do |category_data|
      category = category_data[:category]
      category_data[:variants].each do |variant|
        execute <<-SQL.squish
          INSERT INTO shop_items (category, variant_key, name, cost, grant_amount, image_url, status, description, created_at, updated_at)
          VALUES (
            '#{category}',
            '#{variant[:key]}',
            '#{variant[:name].gsub("'", "''")}',
            #{variant[:cost]},
            #{variant[:grant]},
            '#{variant[:image_url]}',
            'active',
            'This provides a $#{variant[:grant]} HCB card grant to spend on a #{category}',
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
    end
  end

  def down
    execute "DELETE FROM shop_items WHERE category IS NOT NULL AND variant_key IS NOT NULL"
  end
end
