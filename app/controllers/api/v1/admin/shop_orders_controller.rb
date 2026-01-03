# Admin controller for managing shop orders.
# All endpoints require admin role.
class Api::V1::Admin::ShopOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_order, only: [:show, :update]

  # GET /api/v1/admin/shop_orders
  # Lists all orders with optional status filter.
  def index
    orders = ShopOrder.includes(:user, :shop_item).order(created_at: :desc)
    orders = orders.where(status: params[:status]) if params[:status].present?

    render json: { orders: orders.map { |o| order_response(o) } }
  end

  # GET /api/v1/admin/shop_orders/:id
  def show
    render json: { order: order_response(@order) }
  end

  # PATCH /api/v1/admin/shop_orders/:id
  # Updates order status.
  def update
    if @order.update(order_params)
      render json: { order: order_response(@order) }
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = ShopOrder.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Order not found" }, status: :not_found
  end

  def order_params
    params.require(:order).permit(:status, :name)
  end

  def order_response(order)
    {
      id: order.id,
      name: order.name,
      status: order.status,
      user: { id: order.user.id, slack_username: order.user.slack_username },
      item: { id: order.shop_item.id, name: order.shop_item.name },
      created_at: order.created_at
    }
  end
end
