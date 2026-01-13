class AddReviewHistoryToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :review_history, :jsonb
  end
end
