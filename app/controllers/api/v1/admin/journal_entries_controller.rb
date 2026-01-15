class Api::V1::Admin::JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_project
  before_action :set_journal_entry, only: [:show]

  def index
    @entries = @project.journal_entries.order(date: :desc)
    render json: { journal_entries: @entries.map { |e| entry_response(e) } }
  end

  def show
    render json: { journal_entry: entry_response(@entry) }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def set_journal_entry
    @entry = @project.journal_entries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Journal entry not found" }, status: :not_found
  end

  def entry_response(entry)
    {
      id: entry.id,
      project_id: entry.project_id,
      date: entry.date,
      hours: entry.hours,
      content: entry.content,
      tools: entry.tools,
      media_urls: entry.media_urls || [],
      created_at: entry.created_at,
      updated_at: entry.updated_at
    }
  end
end
