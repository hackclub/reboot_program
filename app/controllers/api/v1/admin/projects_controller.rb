# Admin API controller for managing projects.
class Api::V1::Admin::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_project

  # POST /api/v1/admin/projects/:id/approve
  # Approves a project with given hours and reason.
  def approve
    hours = params[:hours].to_f
    reason = params[:reason].to_s.strip
    user_reason = params[:user_reason].to_s.strip

    if reason.blank?
      render json: { error: "Hour justification is required" }, status: :unprocessable_entity
      return
    end

    unless @project.status == "in-review"
      render json: { error: "Project is not in review" }, status: :unprocessable_entity
      return
    end

    @project.approve!(hours: hours, reason: reason, user_reason: user_reason)
    render json: { success: true, project: project_response(@project) }
  end

  # POST /api/v1/admin/projects/:id/reject
  # Rejects a project with a user-facing reason.
  def reject
    user_reason = params[:user_reason].to_s.strip

    if user_reason.blank?
      render json: { error: "User reason is required" }, status: :unprocessable_entity
      return
    end

    unless @project.status == "in-review"
      render json: { error: "Project is not in review" }, status: :unprocessable_entity
      return
    end

    @project.reject!(user_reason: user_reason)
    render json: { success: true, project: project_response(@project) }
  end

  private

  def require_admin
    render json: { error: "Admin access required" }, status: :forbidden unless current_user&.admin?
  end

  def set_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def project_response(project)
    {
      id: project.id,
      name: project.name,
      status: project.status,
      hours: project.hours,
      approved_hours: project.approved_hours,
      approval_reason: project.approval_reason,
      reviewed_at: project.reviewed_at
    }
  end
end
