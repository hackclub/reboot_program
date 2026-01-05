# Adds user-facing reason for approval/rejection to projects.
class AddUserReasonToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :user_reason, :text
  end
end
