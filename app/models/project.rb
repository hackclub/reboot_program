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
  # @return [Boolean] true if linked to any Hackatime projects
  def uses_hackatime?
    hackatime_project_names.present? && hackatime_project_names.any?
  end

  # Total hours from all sources (Hackatime + journal entries).
  # @return [Decimal] sum of hours
  def total_hours
    if uses_hackatime?
      journal_hours = journal_entries.sum(:hours) || 0
      hours + journal_hours
    else
      hours
    end
  end

  # Syncs hours from Hackatime API if linked.
  # Sums hours across all linked Hackatime projects.
  # @return [Boolean] true if synced successfully
  def sync_hackatime_hours!
    return false unless uses_hackatime?
    return false unless user&.slack_id.present?

    start_date = Rails.env.development? ? 1.month.ago.to_date.iso8601 : "2026-01-05"

    total_hours = 0
    hackatime_project_names.each do |project_name|
      hours = HackatimeService.fetch_project_hours(
        user.slack_id,
        project_name,
        start_date: start_date
      )
      total_hours += hours if hours
    end

    update_column(:hours, total_hours)
    true
  end

   # Checks if project can be submitted for review.
   # @return [Boolean] true if pending, rejected, or approved (for new hours)
   def can_request_review?
     status.in?(%w[pending rejected approved])
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
   # Awards CURRENCY_PER_HOUR (50) per approved hour delta.
   # @param hours [Numeric] approved hours to add in this round
   # @param reason [String] internal justification for the approved hours
   # @param user_reason [String] reason shown to the user
   def approve!(hours:, reason:, user_reason: nil)
     first_approval = !previously_approved?
     previous_hours = approved_hours || 0
     new_total_hours = previous_hours + hours

     transaction do
       approval_entry = {
         hours: hours,
         reason: reason,
         user_reason: user_reason.presence,
         reviewed_at: Time.current.iso8601
       }

       review_entry = {
         type: "approved",
         hours: hours,
         user_reason: user_reason.presence,
         reviewed_at: Time.current.iso8601
       }

       update!(
         status: "approved",
         approved_hours: new_total_hours,
         approval_reason: reason,
         user_reason: user_reason.presence,
         reviewed_at: Time.current,
         approval_history: (approval_history || []).push(approval_entry),
         review_history: (review_history || []).push(review_entry)
       )

       currency_delta = hours * CURRENCY_PER_HOUR
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
    rejection_entry = {
      type: "rejected",
      user_reason: user_reason.presence,
      reviewed_at: Time.current.iso8601
    }

    update!(
      status: "rejected",
      user_reason: user_reason.presence,
      reviewed_at: Time.current,
      review_history: (review_history || []).push(rejection_entry)
    )
  end
end
