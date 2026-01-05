# API controller for project journal entries.
class Api::V1::JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_journal_entry, only: [ :show, :update, :destroy ]

  # GET /api/v1/projects/:project_id/journal_entries
  # Lists all journal entries for a project.
  def index
    @entries = @project.journal_entries.order(date: :desc)
    render json: { journal_entries: @entries.map { |e| entry_response(e) } }
  end

  # GET /api/v1/projects/:project_id/journal_entries/:id
  def show
    render json: { journal_entry: entry_response(@entry) }
  end

  # POST /api/v1/projects/:project_id/journal_entries
  # Creates a new journal entry.
  def create
    @entry = @project.journal_entries.build(entry_params)

    if @entry.save
      render json: { journal_entry: entry_response(@entry) }, status: :created
    else
      render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/projects/:project_id/journal_entries/:id
  def update
    if @entry.update(entry_params)
      render json: { journal_entry: entry_response(@entry) }
    else
      render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/projects/:project_id/journal_entries/:id
  def destroy
    @entry.destroy
    head :no_content
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def set_journal_entry
    @entry = @project.journal_entries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Journal entry not found" }, status: :not_found
  end

  def entry_params
    params.require(:journal_entry).permit(:date, :hours, :content, :tools)
  end

  # @param entry [JournalEntry] the entry to serialize
  # @return [Hash] JSON-friendly hash
  def entry_response(entry)
    {
      id: entry.id,
      project_id: entry.project_id,
      date: entry.date,
      hours: entry.hours,
      content: entry.content,
      tools: entry.tools,
      created_at: entry.created_at,
      updated_at: entry.updated_at
    }
  end
end
