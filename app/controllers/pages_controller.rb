# Serves frontend HTML pages.
class PagesController < ActionController::Base
  # Use the application layout
  layout "application"

  # GET /dev_login (development only)
  # Creates or finds a user and logs them in without OAuth.
  def dev_login
    unless Rails.env.development?
      head :not_found and return
    end

    user = User.first
    if user.nil?
      user = User.create!(
        email: "dev@example.com",
        provider: "dev",
        uid: SecureRandom.uuid,
        first_name: "Dev",
        last_name: "User",
        role: "user"
      )
    end

    session[:user_id] = user.id
    session[:jwt] = JwtService.encode(user_id: user.id)
    redirect_to projects_path, notice: "Signed in as #{user.email}"
  end

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
  # Shows the under construction page. Requires authentication.
  def shop
    require_auth or return
    @shop_items = ShopItem.where(status: [ "active", "in stock", "stock", nil, "" ]).order(:cost)
    # Renders app/views/pages/shop.html.erb by default
  end

  # POST /shop/purchase
  # Purchases a shop item or grant variant. Requires authentication.
  # Supports both database-backed items (item_id) and virtual grant variants (category + variant).
  def purchase
    require_auth or return

    # Try to find a database-backed item first
    item = ShopItem.where(status: [ "active", "in stock", "stock", nil, "" ]).find_by(id: params[:item_id]) if params[:item_id].present?

    if item
      # Database-backed item purchase
      cost = item.cost || 0
      name = item.name
      shop_item = item
    else
      # Virtual grant variant purchase (category + variant tier)
      category = params[:category].to_s.strip
      variant = params[:variant].to_s.strip.downcase
      quantity = [ params[:quantity].to_i, 1 ].max

      valid_categories = %w[keyboard mouse monitor headphones webcam]
      bolts_map = { "standard" => 500, "quality" => 1100, "advanced" => 1700, "professional" => 2300 }
      grant_map = { "standard" => 50, "quality" => 110, "advanced" => 170, "professional" => 230 }

      unless valid_categories.include?(category.downcase) && bolts_map.key?(variant)
        redirect_to shop_path, flash: { error: "Invalid item selection" }
        return
      end

      cost = bolts_map[variant] * quantity
      grant_amount = grant_map[variant] * quantity
      name = "#{category.capitalize} #{variant.capitalize} Grant (#{quantity}x) - $#{grant_amount} HCB"

      # Find or create a placeholder ShopItem for grant orders
      shop_item = ShopItem.find_or_create_by!(name: "Grant Order Placeholder") do |si|
        si.cost = 0
        si.status = "system"
        si.description = "System placeholder for grant-based orders"
      end
    end

    if @current_user.balance < cost
      redirect_to shop_path, flash: { error: "Not enough bolts!" }
      return
    end

    ActiveRecord::Base.transaction do
      @current_user.update!(balance: @current_user.balance - cost)
      @current_user.shop_orders.create!(
        shop_item: shop_item,
        name: name,
        status: "pending"
      )
    end

    redirect_to shop_path, flash: { success: "Purchased #{name}!" }
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
