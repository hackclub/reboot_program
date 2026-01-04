# Admin controller for managing projects, users, and orders.
class AdminController < ActionController::Base
  layout "application"
  before_action :require_admin

  # GET /admin
  def index
    redirect_to admin_projects_path
  end

  # GET /admin/projects
  def projects
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 50
    
    @all_projects = Project.includes(:user).order(created_at: :desc)
    @total_projects = @all_projects.count
    @total_pages = (@total_projects.to_f / per_page).ceil
    @current_page = page
    
    offset = (page - 1) * per_page
    @projects = @all_projects.offset(offset).limit(per_page)
    @pending_projects = @all_projects.where(status: "pending").limit(per_page)
  end

  # GET /admin/users
  def users
    @users = User.all.order(created_at: :desc)
  end

  # GET /admin/shop
  def shop
    @shop_items = ShopItem.all.order(created_at: :desc)
  end

  private

  def require_admin
    # TEMP: For UI development, use first user or create one
    @current_user = if session[:user_id]
                     User.find_by(id: session[:user_id])
                   else
                     User.first || User.create!(slack_username: "test_user", role: "admin")
                   end

    unless @current_user&.admin?
      redirect_to projects_path, flash: { error: "Admin access required" }
    end
  end
end
