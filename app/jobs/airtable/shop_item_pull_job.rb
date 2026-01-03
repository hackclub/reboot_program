# Pulls shop items FROM Airtable INTO the local database.
# Run periodically to keep shop items in sync with Airtable source of truth.
class Airtable::ShopItemPullJob < ApplicationJob
  queue_as :literally_whenever

  # Prevents duplicate jobs from running concurrently.
  def self.perform_later(*args)
    return if SolidQueue::Job.where(class_name: name, finished_at: nil).exists?
    super
  end

  # Fetches all shop items from Airtable and upserts them locally.
  def perform
    table.all.each do |airtable_record|
      sync_record(airtable_record)
    end
  end

  private

  # Upserts a single Airtable record into local ShopItem.
  # @param airtable_record [Norairrecord::Record] the Airtable record
  def sync_record(airtable_record)
    attrs = field_mapping(airtable_record)
    item = ShopItem.find_or_initialize_by(airtable_id: airtable_record.id)
    item.update!(attrs)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to sync ShopItem #{airtable_record.id}: #{e.message}")
  end

  # Maps Airtable fields to ShopItem attributes.
  # @param record [Norairrecord::Record] the Airtable record
  # @return [Hash] attributes for ShopItem
  def field_mapping(record)
    {
      name: record["Name"],
      cost: record["Cost"],
      status: record["Status"],
      description: record["Description"],
      link: record["Link"],
      price: record["Price"],
      image_url: record["Image URL"]
    }
  end

  def table
    @table ||= Norairrecord.table(
      ENV.fetch("AIRTABLE_API_KEY"),
      ENV.fetch("AIRTABLE_BASE_ID"),
      ENV.fetch("AIRTABLE_SHOP_ITEMS_TABLE", "Shop Items")
    )
  end
end
