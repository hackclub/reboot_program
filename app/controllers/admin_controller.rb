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
    @projects = Project.includes(:user).order(submitted_at: :desc, created_at: :desc)
    @pending_projects = @projects.where(status: "in-review")
    @all_projects = @projects
  end

  # POST /admin/projects/:id/approve
  def approve_project
    project = Project.find(params[:id])
    hours = params[:approved_hours].to_f
    reason = params[:approval_reason].to_s.strip

    if hours <= 0
      redirect_to admin_projects_path, flash: { error: "Approved hours must be greater than 0" }
      return
    end

    if reason.blank?
      redirect_to admin_projects_path, flash: { error: "Approval reason is required" }
      return
    end

    project.approve!(hours: hours, reason: reason)
    redirect_to admin_projects_path, flash: { success: "Approved #{project.name} for #{hours}h" }
  end

  # POST /admin/projects/:id/reject
  def reject_project
    project = Project.find(params[:id])
    project.reject!
    redirect_to admin_projects_path, flash: { success: "Rejected #{project.name}" }
  end

  private

  def require_admin
    unless session[:user_id]
      redirect_to signin_path
      return
    end

    @current_user = User.find_by(id: session[:user_id])
    unless @current_user&.role == "admin"
      redirect_to projects_path, flash: { error: "Admin access required" }
    end
  end
end
