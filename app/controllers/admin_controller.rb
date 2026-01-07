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
    status_filter = params[:status]

    @all_projects = Project.includes(:user).order(created_at: :desc)
    
    if status_filter.present? && %w[approved pending rejected in-review].include?(status_filter)
      @filtered_projects = @all_projects.where(status: status_filter)
    else
      @filtered_projects = @all_projects
    end
    
    @total_projects = @filtered_projects.count
    @total_pages = (@total_projects.to_f / per_page).ceil
    @current_page = page
    @status_filter = status_filter

    offset = (page - 1) * per_page
    @projects = @filtered_projects.offset(offset).limit(per_page)
    @pending_projects = @all_projects.where(status: "in-review").limit(per_page)
  end

  # GET /admin/projects/:id
  def project_detail
    @project = Project.includes(:user, :journal_entries).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_projects_path, flash: { error: "Project not found" }
  end

  # GET /admin/users
  def users
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 50

    @all_users = User.order(created_at: :desc)
    @total_users = @all_users.count
    @total_pages = (@total_users.to_f / per_page).ceil
    @current_page = page

    offset = (page - 1) * per_page
    @users = @all_users.offset(offset).limit(per_page)
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
