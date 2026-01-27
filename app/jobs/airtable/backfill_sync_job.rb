# Backfills all approved projects without ysws_airtable_id to YSWS Airtable.
# Run manually via: Airtable::BackfillSyncJob.perform_later
class Airtable::BackfillSyncJob < ApplicationJob
  queue_as :literally_whenever

  # Enqueues YswsSubmissionJob for all approved projects missing ysws_airtable_id.
  def perform
    projects = Project.where(status: "approved", ysws_airtable_id: nil)
                      .joins(:user)
                      .where.not(users: { hca_token: nil })

    Rails.logger.info("BackfillSyncJob: Found #{projects.count} approved projects to backfill")

    projects.find_each do |project|
      Airtable::YswsSubmissionJob.perform_later(project.id)
      Rails.logger.info("BackfillSyncJob: Enqueued YswsSubmissionJob for project #{project.id}")
    end

    Rails.logger.info("BackfillSyncJob: Finished enqueuing all YSWS backfill jobs")
  end
end
