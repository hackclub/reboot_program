# Represents a daily journal entry for a project.
# Tracks hours worked, tools used, and session notes.
class JournalEntry < ApplicationRecord
  belongs_to :project

  validates :date, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
  validates :content, presence: true

  # Updates the parent project's total hours after save/destroy.
  after_save :update_project_hours
  after_destroy :update_project_hours

  private

  # Recalculates project hours from all journal entries.
  def update_project_hours
    project.update_column(:hours, project.journal_entries.sum(:hours))
  end
end
