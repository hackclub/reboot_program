# Syncs shop orders TO Airtable from the local database.
# Pushes order data including linked user and item references.
class Airtable::ShopOrderSyncJob < Airtable::BaseSyncJob
  # @return [String] Airtable table name
  def table_name
    ENV.fetch("AIRTABLE_SHOP_ORDERS_TABLE", "Orders")
  end

  # @return [ActiveRecord::Relation] all ShopOrder records
  def records
    ShopOrder.includes(:user, :shop_item)
  end

  # Maps ShopOrder attributes to Airtable fields.
  # Uses airtable_id for linked records (User, ShopItem).
  # @param order [ShopOrder] the order to map
  # @return [Hash] Airtable field values
  def field_mapping(order)
    {
      "Name" => order.name,
      "status" => order.status,
      "user_id" => order.user&.airtable_id ? [order.user.airtable_id] : nil,
      "item_id" => order.shop_item&.airtable_id ? [order.shop_item.airtable_id] : nil,
    }.compact
  end
end
