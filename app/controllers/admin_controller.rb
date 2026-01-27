# Admin controller for managing projects, users, and orders.
class AdminController < ActionController::Base
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authenticatable

  helper ApplicationHelper
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
    @query = params[:q].to_s.strip
    @sort = params[:sort].to_s.strip

    @all_users = User.order(created_at: :desc)

    if @sort == "most_bolts"
      @all_users = @all_users.order(balance: :desc)
    elsif @sort == "least_bolts"
      @all_users = @all_users.order(balance: :asc)
    end

    if @query.present?
      q_like = "%#{@query}%"
      @all_users = @all_users.where(
        "COALESCE(slack_username,'') ILIKE :q OR COALESCE(email,'') ILIKE :q OR COALESCE(role,'') ILIKE :q",
        q: q_like
      )
    end

    @total_users = @all_users.count
    @total_pages = (@total_users.to_f / per_page).ceil
    @current_page = page

    offset = (page - 1) * per_page
    @users = @all_users.offset(offset).limit(per_page)
  end

  def user_detail
    @user = User.includes(:projects).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_users_path, flash: { error: "User not found" }
  end

  def update_user_balance
    @user = User.find(params[:id])
    new_balance = params[:balance].to_f

    if @user.update(balance: new_balance)
      redirect_to admin_user_detail_path(@user), flash: { success: "User balance updated successfully." }
    else
      redirect_to admin_user_detail_path(@user), flash: { error: "Failed to update balance." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_users_path, flash: { error: "User not found" }
  end

  # GET /admin/shop
  def shop
    @shop_items = SHOP_ITEMS
    @shop_orders = ShopOrder.includes(:user, :shop_item).order(created_at: :desc)
    @item_suggestions = ItemSuggestion.includes(:user).order(created_at: :desc)
  end

  def stats
    @total_projects = Project.count
    @pending_projects = Project.where(status: "pending").count
    @in_review_projects = Project.where(status: "in-review").count
    @approved_projects = Project.where(status: "approved").count
    @rejected_projects = Project.where(status: "rejected").count

    @total_logged_hours = Project.sum(:hours)
    @total_approved_hours = Project.sum(:approved_hours)
    @pending_hours = Project.where(status: "in-review").sum(:hours)

    @total_bolts_awarded = @total_approved_hours * Project::CURRENCY_PER_HOUR
    @total_bolts_in_circulation = User.sum(:balance)
    @total_bolts_spent = @total_bolts_awarded - @total_bolts_in_circulation

    @total_users = User.count
    @admin_users = User.where(role: "admin").count
    @verified_users = User.where(idv_verified: true).count
    @users_with_projects = User.joins(:projects).distinct.count
    @users_with_approved_projects = User.joins(:projects).where(projects: { status: "approved" }).distinct.count

    @total_orders = ShopOrder.count
    @pending_orders = ShopOrder.where(status: "pending").count
    @fulfilled_orders = ShopOrder.where(status: "fulfilled").count
    @total_grant_value = ShopOrder.joins(:shop_item).sum("shop_items.grant_amount")
    @orders_by_category = ShopOrder.joins(:shop_item)
                                   .group("shop_items.category")
                                   .count
                                   .sort_by { |_, v| -v }

    @total_journal_entries = JournalEntry.count
    @total_journal_hours = JournalEntry.sum(:hours)

    @top_users_by_hours = Project.where("approved_hours > 0")
                                 .joins(:user)
                                 .group("users.id", "users.slack_username", "users.email")
                                 .sum(:approved_hours)
                                 .sort_by { |_, v| -v }
                                 .first(10)

    @top_users_by_balance = User.where("balance > 0")
                                .order(balance: :desc)
                                .limit(10)
  end

  # GET /admin/jobs
  # Displays Solid Queue job statistics and recent jobs.
  def jobs
    @ready_jobs = SolidQueue::ReadyExecution.count
    @scheduled_jobs = SolidQueue::ScheduledExecution.count
    @failed_jobs = SolidQueue::FailedExecution.count
    @completed_jobs = SolidQueue::Job.where.not(finished_at: nil).count

    @recent_ready = SolidQueue::ReadyExecution.includes(:job).order(created_at: :desc).limit(20)
    @recent_failed = SolidQueue::FailedExecution.includes(:job).order(created_at: :desc).limit(20)
    @recent_completed = SolidQueue::Job.where.not(finished_at: nil).order(finished_at: :desc).limit(20)
    @recent_scheduled = SolidQueue::ScheduledExecution.includes(:job).order(scheduled_at: :asc).limit(20)
  end

  # POST /admin/jobs/:id/retry
  # Retries a failed job by re-enqueuing it.
  def retry_job
    failed = SolidQueue::FailedExecution.find_by(id: params[:id])
    if failed
      failed.retry
      redirect_to admin_jobs_path, flash: { success: "Job re-enqueued" }
    else
      redirect_to admin_jobs_path, flash: { error: "Failed job not found" }
    end
  end

  # DELETE /admin/jobs/:id
  # Discards a failed job permanently.
  def discard_job
    failed = SolidQueue::FailedExecution.find_by(id: params[:id])
    if failed
      failed.discard
      redirect_to admin_jobs_path, flash: { success: "Job discarded" }
    else
      redirect_to admin_jobs_path, flash: { error: "Failed job not found" }
    end
  end

  # POST /admin/jobs/run_airtable_sync
  # Enqueues all Airtable sync jobs to run immediately.
  def run_airtable_sync
    Airtable::UserSyncJob.perform_later
    Airtable::ShopOrderSyncJob.perform_later
    Airtable::ShopItemPullJob.perform_later

    redirect_to admin_jobs_path, flash: { success: "All Airtable sync jobs enqueued" }
  end

  SHOP_ITEMS = [
    { name: "Keyboard", variants: [
      { label: "Standard grant - Redragon K668", key: "standard", bolts: 500, grant: 50 },
      { label: "Quality grant - YUNZII AL80", key: "quality", bolts: 1100, grant: 110 },
      { label: "Advanced grant - Lemokey P1 HE", key: "advanced", bolts: 1700, grant: 170 },
      { label: "Professional grant", key: "professional", bolts: 2200, grant: 220 }
    ] },
    { name: "Mouse", variants: [
      { label: "Standard grant - Logitech G305 Lightspeed", key: "standard", bolts: 300, grant: 30 },
      { label: "Quality grant - Razer DeathAdder", key: "quality", bolts: 500, grant: 50 },
      { label: "Advanced grant - G309 LIGHTSPEED", key: "advanced", bolts: 1000, grant: 100 },
      { label: "Professional grant - MX Master 4", key: "professional", bolts: 1600, grant: 160 }
    ] },
    { name: "Monitor", variants: [
      { label: "Standard grant", key: "standard", bolts: 500, grant: 50 },
      { label: "Quality grant - Dell 24 Monitor SE2425HM", key: "quality", bolts: 1100, grant: 110 },
      { label: "Advanced grant - ViewSonic VX3276-MHD", key: "advanced", bolts: 1700, grant: 180 },
      { label: "Professional grant - SANSUI 32-Inch WQHD", key: "professional", bolts: 2300, grant: 230 }
    ] },
    { name: "Headphones", variants: [
      { label: "Standard grant", key: "standard", bolts: 500, grant: 50 },
      { label: "Quality grant", key: "quality", bolts: 1100, grant: 110 },
      { label: "Professional grant", key: "professional", bolts: 2400, grant: 240 }
    ] },
    { name: "Webcam", variants: [
      { label: "Standard grant", key: "standard", bolts: 500, grant: 50 },
      { label: "Quality grant", key: "quality", bolts: 1400, grant: 140 },
      { label: "Professional grant", key: "professional", bolts: 2300, grant: 230 }
    ] }
  ]

  private

  def require_admin
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]

    unless @current_user&.admin?
      redirect_to root_path, flash: { error: "Admin access required" }
    end
  end
end
