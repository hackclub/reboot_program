class ShopItem < ApplicationRecord
   has_many :shop_orders, dependent: :restrict_with_error
end