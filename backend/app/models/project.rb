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
  # @return [Boolean] true if pending
  def can_request_review?
    status == "pending"
  end

  # Submits project for review.
  def request_review!
    update!(status: "in-review", submitted_at: Time.current)
  end

  # Approves project with given hours.
  # @param hours [Numeric] approved hours
  def approve!(hours:)
    update!(status: "approved", approved_hours: hours, reviewed_at: Time.current)
  end

  # Rejects project.
  def reject!
    update!(status: "rejected", reviewed_at: Time.current)
  end
end
