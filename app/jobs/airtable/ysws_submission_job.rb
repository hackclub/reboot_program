# Uploads approved project to YSWS Project Submission Airtable table.
# Fetches user PII from HCA to fill required address/birthday fields.
class Airtable::YswsSubmissionJob < ApplicationJob
  queue_as :default

  # @param project_id [Integer] the approved project ID
  def perform(project_id)
    project = Project.find(project_id)
    user = project.user

    unless project.status == "approved"
      Rails.logger.warn("YswsSubmissionJob: Project #{project_id} is not approved, skipping")
      return
    end

    unless user.hca_token.present?
      Rails.logger.error("YswsSubmissionJob: User #{user.id} has no HCA token, cannot fetch PII")
      return
    end

    user_info = fetch_user_pii(user.hca_token)
    if user_info.nil?
      Rails.logger.error("YswsSubmissionJob: Failed to fetch PII for user #{user.id}")
      return
    end

    fields = build_fields(project, user, user_info)

    if project.ysws_airtable_id.present?
      update_record(project, fields)
    else
      create_record(project, fields)
    end
  end

  private

  # Fetches user PII from Hack Club Auth.
  # @param hca_token [String] the user's HCA token
  # @return [Hash, nil] user info or nil if fetch fails
  def fetch_user_pii(hca_token)
    result = HackClubAuthService.me(hca_token)
    return nil if result.nil?

    identity = result["identity"] || {}
    {
      email: identity["email"],
      first_name: identity["first_name"],
      last_name: identity["last_name"],
      birthday: identity["birthday"],
      github_username: identity["github_username"],
      address: {
        line1: identity.dig("address", "line1"),
        line2: identity.dig("address", "line2"),
        city: identity.dig("address", "city"),
        state: identity.dig("address", "state"),
        country: identity.dig("address", "country"),
        zip: identity.dig("address", "zip")
      }
    }.with_indifferent_access
  end

  # Builds the field mapping for the YSWS submission.
  # Does NOT set any Automation-* or Loops-* fields.
  # @param project [Project] the approved project
  # @param user [User] the project owner
  # @param user_info [Hash] PII from HCA
  # @return [Hash] Airtable field mapping
  def build_fields(project, user, user_info)
    {
      "Code URL" => project.code_url,
      "Playable URL" => project.playable_url,
      "How did you hear about this?" => "Reboot Program",
      "What are we doing well?" => "",
      "How can we improve?" => "",
      "First Name" => user_info[:first_name] || user.first_name,
      "Last Name" => user_info[:last_name] || user.last_name,
      "Email" => user_info[:email] || user.email,
      "Screenshot" => project.screenshot_url,
      "Description" => project.description,
      "GitHub Username" => user_info[:github_username] || user.slack_username,
      "Address (Line 1)" => user_info.dig(:address, :line1),
      "Address (Line 2)" => user_info.dig(:address, :line2),
      "City" => user_info.dig(:address, :city),
      "State / Province" => user_info.dig(:address, :state),
      "Country" => user_info.dig(:address, :country),
      "ZIP / Postal Code" => user_info.dig(:address, :zip),
      "Birthday" => user_info[:birthday] || user.birthday&.iso8601,
      "Optional - Override Hours Spent" => project.approved_hours.to_f,
      "Optional - Override Hours Spent Justification" => project.approval_reason
    }
  end

  # Creates a new record in Airtable.
  # @param project [Project] the project to sync
  # @param fields [Hash] the field mapping
  def create_record(project, fields)
    record = table.new(fields)
    record.create
    project.update_column(:ysws_airtable_id, record.id)
    Rails.logger.info("YswsSubmissionJob: Created YSWS record #{record.id} for project #{project.id}")
  rescue Norairrecord::Error => e
    Rails.logger.error("YswsSubmissionJob: Failed to create record for project #{project.id}: #{e.message}")
    raise
  end

  # Updates an existing Airtable record.
  # @param project [Project] the project to sync
  # @param fields [Hash] the field mapping
  def update_record(project, fields)
    record = table.find(project.ysws_airtable_id)
    fields.each { |key, value| record[key] = value }
    record.save
    Rails.logger.info("YswsSubmissionJob: Updated YSWS record #{project.ysws_airtable_id} for project #{project.id}")
  rescue Norairrecord::RecordNotFoundError
    project.update_column(:ysws_airtable_id, nil)
    create_record(project, fields)
  rescue Norairrecord::Error => e
    Rails.logger.error("YswsSubmissionJob: Failed to update record for project #{project.id}: #{e.message}")
    raise
  end

  def table
    @table ||= Norairrecord.table(
      ENV.fetch("AIRTABLE_API_KEY"),
      ENV.fetch("AIRTABLE_BASE_ID"),
      "YSWS Project Submission"
    )
  end
end
