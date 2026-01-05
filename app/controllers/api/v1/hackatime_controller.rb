# API controller for Hackatime integration.
class Api::V1::HackatimeController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/hackatime/projects
  # Returns the user's Hackatime projects with hours.
  def projects
    unless current_user.slack_id.present?
      render json: { error: "No Slack ID found", projects: [] }
      return
    end

    stats = HackatimeService.fetch_stats(current_user.slack_id, start_date: hackatime_start_date)

    if stats.nil?
      render json: { error: "Failed to fetch Hackatime data", projects: [] }
      return
    end

    if stats[:banned]
      render json: { error: "Account flagged by Hackatime", projects: [] }
      return
    end

    projects = stats[:projects].map do |name, seconds|
      { name: name, hours: (seconds / 3600.0).round(2) }
    end.sort_by { |p| -p[:hours] }

    render json: { projects: projects }
  end

  private

  # Returns the start date for Hackatime queries.
  # In development, uses one month ago; in production, uses program start date.
  # @return [String] date in YYYY-MM-DD format
  def hackatime_start_date
    if Rails.env.development?
      1.month.ago.to_date.iso8601
    else
      "2026-01-05"
    end
  end
end
