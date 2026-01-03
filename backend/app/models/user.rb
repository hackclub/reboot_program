class User < ApplicationRecord 
    has_many :shop_order, dependent: :destroy
end