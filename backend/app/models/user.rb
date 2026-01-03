# Represents a user in the system, synced TO Airtable.
class User < ApplicationRecord
  has_many :shop_orders, dependent: :destroy

  ROLES = %w[user admin].freeze

  validates :role, inclusion: { in: ROLES }

  # Checks if user has completed IDV verification.
  # @return [Boolean] true if verified
  def idv_verified?
    idv_verified == true
  end

  # Checks if user has admin role.
  # @return [Boolean] true if admin
  def admin?
    role == "admin"
  end

  # Checks if user has regular user role.
  # @return [Boolean] true if regular user
  def user?
    role == "user"
  end
end