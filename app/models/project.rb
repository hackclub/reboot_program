# Represents a user's project submission.
class Project < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending in-review approved rejected].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :in_review, -> { where(status: "in-review") }
  scope :approved, -> { where(status: "approved") }

  # Checks if project can be submitted for review.
  # @return [Boolean] true if pending or rejected
  def can_request_review?
    status == "pending" || status == "rejected"
  end

  # Submits project for review.
  def request_review!
    update!(status: "in-review", submitted_at: Time.current)
  end

  # Approves project with given hours and credits user's balance.
  # Also queues a job to sync to YSWS Airtable.
  # @param hours [Numeric] approved hours
  # @param reason [String] justification for the approved hours
  def approve!(hours:, reason:)
    transaction do
      update!(status: "approved", approved_hours: hours, approval_reason: reason, reviewed_at: Time.current)
      user.update!(balance: user.balance + hours)
    end
    Airtable::YswsSubmissionJob.perform_later(id)
  end

  # Rejects project.
  def reject!
    update!(status: "rejected", reviewed_at: Time.current)
  end
end
