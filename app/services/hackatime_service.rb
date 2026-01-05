# Service for fetching project stats from Hackatime API.
# Uses the public stats endpoint only (no private API).
class HackatimeService
  BASE_URL = "https://hackatime.hackclub.com"
  START_DATE = "2025-12-15"

  # Fetches project stats for a user.
  # @param hackatime_uid [String] the user's Hackatime username/ID
  # @param start_date [String] start date in YYYY-MM-DD format
  # @param end_date [String, nil] optional end date
  # @return [Hash, nil] { projects: { "name" => seconds }, banned: bool } or nil on error
  def self.fetch_stats(hackatime_uid, start_date: START_DATE, end_date: nil)
    params = { features: "projects", start_date: start_date }
    params[:end_date] = end_date if end_date

    response = connection.get("users/#{hackatime_uid}/stats", params)

    if response.success?
      data = JSON.parse(response.body)
      projects = data.dig("data", "projects") || []
      {
        projects: projects.to_h { |p| [ p["name"], p["total_seconds"].to_i ] },
        banned: data.dig("trust_factor", "trust_value") == 1
      }
    else
      Rails.logger.error("HackatimeService error: #{response.status} - #{response.body}")
      nil
    end
  rescue => e
    Rails.logger.error("HackatimeService exception: #{e.message}")
    nil
  end

  # Fetches hours for a specific project within a date range.
  # @param hackatime_uid [String] the user's Hackatime username/ID
  # @param project_name [String] the project name to filter by
  # @param start_date [String] start date in YYYY-MM-DD format
  # @param end_date [String, nil] optional end date
  # @return [Float, nil] hours worked or nil on error
  def self.fetch_project_hours(hackatime_uid, project_name, start_date: START_DATE, end_date: nil)
    params = {
      features: "projects",
      start_date: start_date,
      total_seconds: true,
      filter_by_project: project_name
    }
    params[:end_date] = end_date if end_date

    response = connection.get("users/#{hackatime_uid}/stats", params)

    if response.success?
      data = JSON.parse(response.body)
      total_seconds = data["total_seconds"].to_i
      (total_seconds / 3600.0).round(2)
    else
      Rails.logger.error("HackatimeService.fetch_project_hours error: #{response.status}")
      nil
    end
  rescue => e
    Rails.logger.error("HackatimeService.fetch_project_hours exception: #{e.message}")
    nil
  end

  class << self
    private

    def connection
      @connection ||= Faraday.new(url: "#{BASE_URL}/api/v1") do |conn|
        conn.headers["Content-Type"] = "application/json"
      end
    end
  end
end
