# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Pull shop items from Airtable to seed the database.
# Requires AIRTABLE_API_KEY and AIRTABLE_BASE_ID environment variables.
puts "Seeding shop items from Airtable..."

table = Norairrecord.table(
  ENV.fetch("AIRTABLE_API_KEY"),
  ENV.fetch("AIRTABLE_BASE_ID"),
  ENV.fetch("AIRTABLE_SHOP_ITEMS_TABLE", "Shop Items")
)

table.all.each do |record|
  item = ShopItem.find_or_initialize_by(airtable_id: record.id)
  item.update!(
    name: record["Name"],
    cost: record["Cost"],
    status: record["Status"],
    description: record["Description"],
    link: record["Link"],
    price: record["Price"],
    image_url: record["Image URL"]
  )
  puts "  Synced: #{item.name}"
end

puts "Done! Seeded #{ShopItem.count} shop items."
