# Adds Hackatime project linking to projects.
class AddHackatimeProjectNameToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :hackatime_project_name, :string
  end
end
