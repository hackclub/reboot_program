# Admin controller for managing shop orders.
# All endpoints require admin role.
class Api::V1::Admin::ShopOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_order, only: [ :show, :update ]

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
  # Updates order status. Refunds bolts if cancelled.
  def update
    old_status = @order.status
    new_status = order_params[:status]
    refund_amount = 0

    ActiveRecord::Base.transaction do
      if new_status == "cancelled" && old_status != "cancelled"
        refund_amount = @order.cost.to_f
        refund_amount = @order.shop_item&.cost.to_f if refund_amount.zero?
        if refund_amount > 0
          user = User.find(@order.user_id)
          user.update!(balance: user.balance + refund_amount)
        end
      end

      unless @order.update(order_params)
        raise ActiveRecord::Rollback
      end
    end

    if @order.errors.any?
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    else
      render json: {
        order: order_response(@order),
        refunded: new_status == "cancelled" && old_status != "cancelled" && refund_amount > 0,
        refund_amount: refund_amount
      }
    end
  end

  private

  def set_order
    @order = ShopOrder.includes(:user, :shop_item).find(params[:id])
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
