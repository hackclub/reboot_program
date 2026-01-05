# Admin API controller for managing shop items.
class Api::V1::Admin::ShopItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_shop_item, only: [ :show, :update, :destroy ]

  # GET /api/v1/admin/shop_items
  def index
    @items = ShopItem.order(created_at: :desc)
    render json: { shop_items: @items.map { |i| item_response(i) } }
  end

  # GET /api/v1/admin/shop_items/:id
  def show
    render json: { shop_item: item_response(@item) }
  end

  # POST /api/v1/admin/shop_items
  def create
    @item = ShopItem.new(item_params)

    if @item.save
      render json: { shop_item: item_response(@item) }, status: :created
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/admin/shop_items/:id
  def update
    if @item.update(item_params)
      render json: { shop_item: item_response(@item) }
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/admin/shop_items/:id
  def destroy
    @item.destroy
    head :no_content
  end

  private

  def require_admin
    render json: { error: "Admin access required" }, status: :forbidden unless current_user&.admin?
  end

  def set_shop_item
    @item = ShopItem.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shop item not found" }, status: :not_found
  end

  def item_params
    params.require(:shop_item).permit(:name, :description, :cost, :status, :image_url, :link, :price)
  end

  def item_response(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      cost: item.cost,
      price: item.price,
      status: item.status,
      image_url: item.image_url,
      link: item.link,
      airtable_id: item.airtable_id,
      created_at: item.created_at
    }
  end
end
