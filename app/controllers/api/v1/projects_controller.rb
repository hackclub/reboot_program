# API controller for user projects.
class Api::V1::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :update, :destroy, :request_review, :sync_hackatime ]

  # GET /api/v1/projects
  # Lists all projects for the current user.
  def index
    @projects = current_user.projects.order(created_at: :desc)
    render json: { projects: @projects.map { |p| project_response(p) } }
  end

  # GET /api/v1/projects/:id
  def show
    render json: { project: project_response(@project) }
  end

  # POST /api/v1/projects
  # Creates a new project.
  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      render json: { project: project_response(@project) }, status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/projects/:id
  # Updates a project.
  def update
    if @project.update(project_params)
      render json: { project: project_response(@project) }
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:id
  def destroy
    @project.destroy
    head :no_content
  end

  # POST /api/v1/projects/:id/request_review
  # Submits project for review (ships it).
  def request_review
    unless @project.can_request_review?
      render json: { error: "Project cannot be shipped" }, status: :unprocessable_entity
      return
    end

    unless @project.ready_to_ship?
      render json: { error: "Please fill in all required fields: description, code URL, playable URL, screenshot URL" }, status: :unprocessable_entity
      return
    end

    @project.request_review!
    render json: { project: project_response(@project) }
  end

  # POST /api/v1/projects/:id/sync_hackatime
  # Syncs hours from Hackatime for this project.
  def sync_hackatime
    unless @project.uses_hackatime?
      render json: { error: "Project not linked to Hackatime" }, status: :unprocessable_entity
      return
    end

    if @project.sync_hackatime_hours!
      render json: { project: project_response(@project) }
    else
      render json: { error: "Failed to sync hours from Hackatime" }, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def project_params
    params.require(:project).permit(:name, :description, :code_url, :playable_url, :screenshot_url, :hours, :hackatime_project_name)
  end

  def project_response(project)
    {
      id: project.id,
      name: project.name,
      description: project.description,
      status: project.status,
      code_url: project.code_url,
      playable_url: project.playable_url,
      screenshot_url: project.screenshot_url,
      hours: project.hours,
      approved_hours: project.approved_hours,
      submitted_at: project.submitted_at,
      reviewed_at: project.reviewed_at,
      created_at: project.created_at,
      hackatime_project_name: project.hackatime_project_name,
      uses_hackatime: project.uses_hackatime?
    }
  end
end
