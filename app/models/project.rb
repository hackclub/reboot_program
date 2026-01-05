# Represents a user's project submission.
class Project < ApplicationRecord
  belongs_to :user
  has_many :journal_entries, dependent: :destroy

  STATUSES = %w[pending in-review approved rejected].freeze
  CURRENCY_PER_HOUR = 50

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :in_review, -> { where(status: "in-review") }
  scope :approved, -> { where(status: "approved") }

  # Checks if this project tracks hours via Hackatime.
  # @return [Boolean] true if linked to a Hackatime project
  def uses_hackatime?
    hackatime_project_name.present?
  end

  # Syncs hours from Hackatime API if linked.
  # @return [Boolean] true if synced successfully
  def sync_hackatime_hours!
    return false unless uses_hackatime?
    return false unless user.slack_id.present?

    start_date = Rails.env.development? ? 1.month.ago.to_date.iso8601 : "2026-01-05"

    hours = HackatimeService.fetch_project_hours(
      user.slack_id,
      hackatime_project_name,
      start_date: start_date
    )

    if hours
      update_column(:hours, hours)
      true
    else
      false
    end
  end

  # Checks if project can be submitted for review.
  # @return [Boolean] true if pending or rejected
  def can_request_review?
    status == "pending" || status == "rejected"
  end

  # Checks if project has all required fields to ship.
  # @return [Boolean] true if all shipping fields are present
  def ready_to_ship?
    description.present? && code_url.present? && playable_url.present? && screenshot_url.present?
  end

  # Submits project for review.
  def request_review!
    update!(status: "in-review", submitted_at: Time.current)
  end

  # Approves project with given hours and credits user's balance.
  # First approval sends to YSWS Airtable; re-approvals update existing record.
  # Awards CURRENCY_PER_HOUR (50) per approved hour.
  # @param hours [Numeric] approved hours
  # @param reason [String] internal justification for the approved hours
  # @param user_reason [String] reason shown to the user
  def approve!(hours:, reason:, user_reason: nil)
    first_approval = !previously_approved?
    previous_hours = approved_hours || 0

    transaction do
      update!(
        status: "approved",
        approved_hours: hours,
        approval_reason: reason,
        user_reason: user_reason.presence,
        reviewed_at: Time.current
      )
      hours_delta = hours - previous_hours
      currency_delta = hours_delta * CURRENCY_PER_HOUR
      user.update!(balance: user.balance + currency_delta)
    end

    Airtable::YswsSubmissionJob.perform_later(id) if first_approval || ysws_airtable_id.present?
  end

  # Checks if this project was previously approved (has a YSWS Airtable record).
  # @return [Boolean] true if previously synced to YSWS
  def previously_approved?
    ysws_airtable_id.present?
  end

  # Rejects project with a user-facing reason.
  # @param user_reason [String] reason shown to the user
  def reject!(user_reason: nil)
    update!(status: "rejected", user_reason: user_reason.presence, reviewed_at: Time.current)
  end
end
