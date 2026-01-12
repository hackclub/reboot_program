class AddApprovalHistoryToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :approval_history, :jsonb
  end
end
