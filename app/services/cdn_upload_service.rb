class CdnUploadService
  ALLOWED_EXTENSIONS = %w[.png .jpg .jpeg .mp4 .avi .mov].freeze
  ALLOWED_MIME_TYPES = %w[
    image/png
    image/jpeg
    video/mp4
    video/x-msvideo
    video/quicktime
  ].freeze
  MAX_FILE_SIZE = 50.megabytes
  CDN_API_TOKEN = "beans".freeze

  class UploadError < StandardError; end
  class InvalidFileError < StandardError; end

  def initialize(file)
    @file = file
  end

  def upload!
    validate_file!
    upload_to_cdn
  end

  private

  def validate_file!
    raise InvalidFileError, "No file provided" unless @file.present?
    raise InvalidFileError, "File too large (max 50MB)" if @file.size > MAX_FILE_SIZE

    extension = File.extname(@file.original_filename).downcase
    raise InvalidFileError, "Invalid file type" unless ALLOWED_EXTENSIONS.include?(extension)

    content_type = @file.content_type
    raise InvalidFileError, "Invalid content type" unless ALLOWED_MIME_TYPES.include?(content_type)

    validate_file_signature!
  end

  def validate_file_signature!
    @file.rewind
    header = @file.read(12)
    @file.rewind

    valid = case @file.content_type
    when "image/png"
      header&.bytes&.first(8) == [ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A ]
    when "image/jpeg"
      header&.bytes&.first(2) == [ 0xFF, 0xD8 ]
    when "video/mp4"
      header&.include?("ftyp")
    when "video/x-msvideo"
      header&.bytes&.first(4) == [ 0x52, 0x49, 0x46, 0x46 ]
    when "video/quicktime"
      header&.include?("moov") || header&.include?("ftyp")
    else
      false
    end

    raise InvalidFileError, "File signature mismatch" unless valid
  end

  def upload_to_cdn
    @file.rewind
    file_data = @file.read
    base64_data = Base64.strict_encode64(file_data)
    data_url = "data:#{@file.content_type};base64,#{base64_data}"

    response = Faraday.post("https://cdn.hackclub.com/api/v3/new") do |req|
      req.headers["Authorization"] = "Bearer #{CDN_API_TOKEN}"
      req.headers["Content-Type"] = "application/json"
      req.body = [ data_url ].to_json
    end

    raise UploadError, "CDN upload failed: #{response.status}" unless response.success?

    result = JSON.parse(response.body)
    files = result["files"]

    raise UploadError, "No files returned from CDN" if files.blank?

    files.first["deployedUrl"]
  end
end
