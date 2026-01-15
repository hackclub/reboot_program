# Admin controller for managing users.
# All endpoints require admin role.
class Api::V1::Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: [ :show, :update, :destroy ]

  # GET /api/v1/admin/users
  # Lists all users with pagination.
  def index
    page = params[:page]&.to_i || 1
    per_page = [ params[:per_page]&.to_i || 25, 100 ].min

    users = User.order(created_at: :desc)
                .offset((page - 1) * per_page)
                .limit(per_page)

    render json: {
      users: users.map { |u| user_response(u) },
      meta: { page: page, per_page: per_page, total: User.count }
    }
  end

  # GET /api/v1/admin/users/:id
  # Shows a single user.
  def show
    render json: { user: user_response(@user) }
  end

  # PATCH /api/v1/admin/users/:id
  # Updates user attributes (role, idv_verified, etc.)
  def update
    if params[:user][:role].present? && @user.id == current_user.id
      render json: { error: "Cannot change your own role" }, status: :forbidden
      return
    end

    if @user.update(user_params)
      render json: { user: user_response(@user) }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/admin/users/:id
  # Soft-deletes or destroys a user.
  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:role, :idv_verified)
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      slack_id: user.slack_id,
      slack_username: user.slack_username,
      role: user.role,
      idv_verified: user.idv_verified,
      created_at: user.created_at
    }
  end
end
