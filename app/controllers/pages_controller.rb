# Serves frontend HTML pages.
class PagesController < ActionController::Base
  # Use the application layout
  layout "application"

  # GET /
  # Redirects to projects if authenticated, renders signin otherwise.
  def home
    if session[:user_id]
      redirect_to projects_path
    else
      render :signin
    end
  end

  # GET /signin
  # Shows the signin page with HCA OAuth button.
  def signin
    # If already signed in, redirect to projects
    redirect_to projects_path if session[:user_id]
  end

  # GET /projects
  # Shows the user's projects. Requires authentication.
  def projects
    unless session[:user_id]
      redirect_to root_path and return
    end

    @current_user = User.find_by(id: session[:user_id])
    unless @current_user
      session.delete(:user_id)
      redirect_to root_path and return
    end

    @projects = @current_user.projects.order(created_at: :desc)
    @selected_project = @projects.find_by(id: params[:selected]) || @projects.first
  end

  # POST /projects
  # Creates a new project.
  def create_project
    require_auth or return

    @project = @current_user.projects.build(project_params)

    if @project.save
      redirect_to projects_path(selected: @project.id), flash: { success: "Project created!" }
    else
      redirect_to projects_path, flash: { error: @project.errors.full_messages.join(", ") }
    end
  end

  # POST /projects/:id/request_review
  # Submits a project for review.
  def request_review
    require_auth or return

    project = @current_user.projects.find_by(id: params[:id])

    unless project
      redirect_to projects_path, flash: { error: "Project not found" }
      return
    end

    unless project.can_request_review?
      redirect_to projects_path(selected: project.id), flash: { error: "Project cannot be shipped" }
      return
    end

    unless project.ready_to_ship?
      redirect_to projects_path(selected: project.id), flash: { error: "Please fill in all required fields: description, code URL, playable URL, screenshot URL" }
      return
    end

    project.request_review!
    redirect_to projects_path(selected: project.id), flash: { success: "Project shipped! Awaiting review." }
  end

  # GET /shop
  # Shows the shop page. Requires authentication.
  def shop
    require_auth or return
    @shop_items = ShopItem.where(status: [ "active", "in stock", "stock", nil, "" ]).order(:cost)
  end

  # POST /shop/purchase
  # Purchases a shop item. Requires authentication.
  def purchase
    require_auth or return

    item = ShopItem.where(status: [ "active", "in stock", "stock", nil, "" ]).find_by(id: params[:item_id])

    unless item
      redirect_to shop_path, flash: { error: "Item not found" }
      return
    end

    if @current_user.balance < (item.cost || 0)
      redirect_to shop_path, flash: { error: "Not enough screws!" }
      return
    end

    ActiveRecord::Base.transaction do
      @current_user.update!(balance: @current_user.balance - item.cost)
      @current_user.shop_orders.create!(
        shop_item: item,
        name: item.name,
        status: "pending"
      )
    end

    redirect_to shop_path, flash: { success: "Purchased #{item.name}!" }
  rescue ActiveRecord::RecordInvalid => e
    redirect_to shop_path, flash: { error: "Purchase failed: #{e.message}" }
  end

  # GET /purchases
  # Shows the user's purchases. Requires authentication.
  def purchases
    require_auth or return
    @orders = @current_user.shop_orders.includes(:shop_item).order(created_at: :desc)
  end

  # GET /faq
  # Shows the FAQ page. Requires authentication.
  def faq
    require_auth or return
  end

  # DELETE /signout
  # Signs out the user and redirects to signin.
  def signout
    session.delete(:user_id)
    session.delete(:jwt)
    redirect_to root_path, notice: "Signed out successfully"
  end

  private

  # Authenticates the user via session.
  # Redirects to signin if not authenticated.
  # @return [Boolean] true if authenticated
  def require_auth
    unless session[:user_id]
      redirect_to root_path
      return false
    end

    @current_user = User.find_by(id: session[:user_id])
    unless @current_user
      session.delete(:user_id)
      redirect_to root_path
      return false
    end

    true
  end

  def project_params
    params.require(:project).permit(:name, :description, :code_url, :playable_url, :hours, :hackatime_project_name)
  end
end
