class ItemSuggestion < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending added rejected].freeze
  COST = 30

  validates :item_name, presence: true
  validates :item_link, presence: true
  validates :status, inclusion: { in: STATUSES }
end
