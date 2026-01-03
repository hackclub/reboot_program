# Handles submissions to the YSWS (You Ship We Ship) Airtable table.
# Uses HCA token to autofill user PII and creates records in Airtable.
class YswsSubmissionService
  # Submits a project to YSWS Airtable for the given user.
  # @param user [User] the authenticated user (must be IDV verified)
  # @param project_data [Hash] the project submission data
  # @param hca_token [String] the Hack Club Auth token for PII autofill
  # @return [Hash] { success: true, record_id: id } or { success: false, error: message }
  def self.submit(user:, project_data:, hca_token:)
    new(user: user, project_data: project_data, hca_token: hca_token).submit
  end

  def initialize(user:, project_data:, hca_token:)
    @user = user
    @project_data = project_data
    @hca_token = hca_token
  end

  # Performs the submission to YSWS Airtable.
  # @return [Hash] result with success status and record_id/error
  def submit
    return idv_error unless @user.idv_verified?

    user_info = fetch_user_pii
    return pii_error if user_info.nil?

    record = create_airtable_record(user_info)
    { success: true, record_id: record.id }
  rescue Norairrecord::Error => e
    { success: false, error: "Airtable error: #{e.message}" }
  rescue Faraday::Error => e
    { success: false, error: "API error: #{e.message}" }
  end

  private

  # Fetches user PII from Hack Club Auth using the provided token.
  # @return [Hash, nil] user info or nil if fetch fails
  def fetch_user_pii
    result = HackClubAuthService.me(@hca_token)
    return nil if result.nil?

    # Extract identity info for PII
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

  # Creates a new record in the YSWS Airtable table.
  # @param user_info [Hash] PII from Hack Club Auth
  # @return [Norairrecord::Record] the created record
  def create_airtable_record(user_info)
    record = table.new(build_fields(user_info))
    record.create
    record
  end

  # Builds Airtable fields from project data and user PII.
  # Does NOT touch Loops-* or Automation-* fields.
  # @param user_info [Hash] PII from Hack Club Auth
  # @return [Hash] Airtable field values
  def build_fields(user_info)
    {
      "Code URL" => @project_data[:code_url],
      "Playable URL" => @project_data[:playable_url],
      "How did you hear about this?" => @project_data[:how_heard],
      "What are we doing well?" => @project_data[:doing_well],
      "How can we improve?" => @project_data[:improve],
      "First Name" => user_info[:first_name],
      "Last Name" => user_info[:last_name],
      "Email" => user_info[:email],
      "Screenshot" => @project_data[:screenshot_url],
      "Description" => @project_data[:description],
      "GitHub Username" => user_info[:github_username] || @project_data[:github_username],
      "Address (Line 1)" => user_info.dig(:address, :line1),
      "Address (Line 2)" => user_info.dig(:address, :line2),
      "City" => user_info.dig(:address, :city),
      "State / Province" => user_info.dig(:address, :state),
      "Country" => user_info.dig(:address, :country),
      "ZIP / Postal Code" => user_info.dig(:address, :zip),
      "Birthday" => user_info[:birthday],
      "Optional - Override Hours Spent" => @project_data[:override_hours],
      "Optional - Override Hours Spent Justification" => @project_data[:override_hours_justification]
    }.compact
  end

  def table
    @table ||= Norairrecord.table(
      ENV.fetch("AIRTABLE_API_KEY"),
      ENV.fetch("AIRTABLE_BASE_ID"),
      ENV.fetch("AIRTABLE_YSWS_TABLE", "YSWS Submissions")
    )
  end

  def idv_error
    { success: false, error: "User must be IDV verified to submit" }
  end

  def pii_error
    { success: false, error: "Failed to fetch user information from Hack Club" }
  end
end
