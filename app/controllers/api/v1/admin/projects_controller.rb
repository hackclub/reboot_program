# Admin API controller for managing projects.
class Api::V1::Admin::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
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

    unless @project.status.in?(%w[in-review pending rejected])
      render json: { error: "Project cannot be reviewed in its current state" }, status: :unprocessable_entity
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

    unless @project.status.in?(%w[in-review pending rejected])
      render json: { error: "Project cannot be reviewed in its current state" }, status: :unprocessable_entity
      return
    end

    @project.reject!(user_reason: user_reason)
    render json: { success: true, project: project_response(@project) }
  end

  def update
    user = @project.user
    old_approved_hours = @project.approved_hours || 0
    new_approved_hours = params[:approved_hours].present? ? params[:approved_hours].to_f : old_approved_hours
    new_status = params[:status]
    bolts_delta = 0

    Project.transaction do
      if new_status == "rejected" && @project.status != "rejected"
        new_approved_hours = 0
        bolts_delta = -old_approved_hours * Project::CURRENCY_PER_HOUR
      elsif new_approved_hours != old_approved_hours
        hours_delta = new_approved_hours - old_approved_hours
        bolts_delta = hours_delta * Project::CURRENCY_PER_HOUR
      end

      if bolts_delta != 0
        new_balance = [ user.balance + bolts_delta, 0 ].max
        user.update!(balance: new_balance)
      end

      update_attrs = {}
      update_attrs[:hours] = params[:hours].to_f if params[:hours].present?
      update_attrs[:approved_hours] = new_approved_hours if params[:approved_hours].present? || new_status == "rejected"
      update_attrs[:status] = new_status if new_status.present?

      unless @project.update(update_attrs)
        raise ActiveRecord::Rollback
      end
    end

    if @project.errors.any?
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    else
      render json: {
        success: true,
        project: project_response(@project),
        bolts_delta: bolts_delta,
        new_user_balance: user.reload.balance
      }
    end
  end

  def destroy
    user = @project.user
    approved_hours = @project.approved_hours || 0

    Project.transaction do
      if approved_hours > 0
        bolts_to_revoke = approved_hours * Project::CURRENCY_PER_HOUR
        new_balance = [ user.balance - bolts_to_revoke, 0 ].max
        user.update!(balance: new_balance)
      end

      @project.destroy!
    end

    render json: { success: true, bolts_revoked: approved_hours * Project::CURRENCY_PER_HOUR }
  end

  private

  def project_params
    params.permit(:hours, :approved_hours)
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
