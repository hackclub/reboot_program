class ChangeHackatimeProjectNameToArray < ActiveRecord::Migration[8.0]
  def change
    rename_column :projects, :hackatime_project_name, :hackatime_project_name_old

    add_column :projects, :hackatime_project_names, :jsonb, default: []

    reversible do |dir|
      dir.up do
        Project.reset_column_information
        execute <<-SQL
          UPDATE projects
          SET hackatime_project_names = CASE#{' '}
            WHEN hackatime_project_name_old IS NOT NULL AND hackatime_project_name_old != ''
            THEN jsonb_build_array(hackatime_project_name_old)
            ELSE '[]'::jsonb
          END
        SQL
      end

      dir.down do
        Project.reset_column_information
        execute <<-SQL
          UPDATE projects
          SET hackatime_project_name_old = CASE
            WHEN jsonb_array_length(hackatime_project_names) > 0
            THEN hackatime_project_names->0
            ELSE NULL
          END
        SQL
      end
    end

    remove_column :projects, :hackatime_project_name_old
  end
end
