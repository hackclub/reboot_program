# Provides role-based authorization methods for controllers.
# Use `before_action :require_admin!` to restrict endpoints to admins.
module Authorizable
  extend ActiveSupport::Concern

  # Requires the current user to have admin role.
  # Renders 403 Forbidden if not an admin.
  def require_admin!
    return if current_user&.admin?

    render json: { error: "Admin access required" }, status: :forbidden
  end

  # Requires the current user to have at least user role (any authenticated user).
  # Renders 401 Unauthorized if not authenticated.
  def require_user!
    return if current_user.present?

    render json: { error: "Authentication required" }, status: :unauthorized
  end
end
