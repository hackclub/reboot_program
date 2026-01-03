# Handles YSWS (You Ship We Ship) submissions.
# Requires IDV verification and uses stored HCA token for PII autofill.
class Api::V1::YswsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_idv_verified!
  before_action :require_valid_hca_token!

  # POST /api/v1/ysws/submit
  # Submits a project to YSWS.
  #
  # @param project [Hash] project data (code_url, playable_url, etc.)
  # @return [JSON] { success: true, record_id: ... } or { error: ... }
  def submit
    result = YswsSubmissionService.submit(
      user: current_user,
      project_data: project_params,
      hca_token: current_user.hca_token
    )

    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  # Blocks non-IDV verified users from submitting.
  def require_idv_verified!
    return if current_user.idv_verified?

    render json: { error: "IDV verification required to submit to YSWS" }, status: :forbidden
  end

  # Ensures user has a valid (non-expired) HCA token stored.
  def require_valid_hca_token!
    if current_user.hca_token.blank?
      render json: { error: "No HCA token stored. Please re-authenticate." }, status: :unauthorized
      return
    end

    if current_user.hca_token_expires_at&.past?
      render json: { error: "HCA token expired. Please re-authenticate." }, status: :unauthorized
    end
  end

  # Strong params for project submission.
  def project_params
    params.require(:project).permit(
      :code_url,
      :playable_url,
      :how_heard,
      :doing_well,
      :improve,
      :screenshot_url,
      :description,
      :github_username,
      :override_hours,
      :override_hours_justification
    )
  end
end
