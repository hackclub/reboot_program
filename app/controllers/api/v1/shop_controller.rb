# API controller for shop operations.
class Api::V1::ShopController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/shop/items
  # Lists all active shop items.
  def items
    @items = ShopItem.where(status: ["active", "in stock", "stock", nil, ""]).order(:cost)
    render json: { items: @items.map { |i| item_response(i) } }
  end

  # POST /api/v1/shop/purchase
  # Purchases a shop item.
  def purchase
    item = ShopItem.where(status: ["active", "in stock", "stock", nil, ""]).find_by(id: params[:item_id])

    unless item
      render json: { error: "Item not found" }, status: :not_found
      return
    end

    if current_user.balance < item.cost
      render json: { error: "Insufficient balance" }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      current_user.update!(balance: current_user.balance - item.cost)
      @order = current_user.shop_orders.create!(
        shop_item: item,
        name: item.name,
        status: "pending"
      )
    end

    render json: {
      order: order_response(@order),
      new_balance: current_user.balance
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def item_response(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      cost: item.cost,
      image_url: item.image_url
    }
  end

  def order_response(order)
    {
      id: order.id,
      name: order.name,
      status: order.status,
      created_at: order.created_at
    }
  end
end
