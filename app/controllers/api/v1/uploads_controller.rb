class Api::V1::UploadsController < ApplicationController
  before_action :authenticate_user!

  def create
    file = params[:file]

    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "No file provided" }, status: :bad_request
    end

    service = CdnUploadService.new(file)
    cdn_url = service.upload!

    render json: { url: cdn_url }
  rescue CdnUploadService::InvalidFileError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue CdnUploadService::QuotaExceededError => e
    Rails.logger.error("CDN quota exceeded: #{e.message}")
    render json: { error: "Storage quota exceeded. Please contact support." }, status: :payment_required
  rescue CdnUploadService::UploadError => e
    Rails.logger.error("CDN upload error: #{e.message}")
    render json: { error: "Upload failed. Please try again." }, status: :service_unavailable
  end
end
