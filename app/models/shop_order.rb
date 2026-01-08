class ShopOrder < ApplicationRecord
  belongs_to :user
  belongs_to :shop_item

  after_save :sync_to_airtable

  private

  def sync_to_airtable
    Airtable::ShopOrderSyncJob.perform_later
  end
end