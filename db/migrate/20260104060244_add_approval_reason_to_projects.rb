class AddApprovalReasonToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :approval_reason, :text
  end
end
