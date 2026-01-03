# Creates the projects table for user submissions.
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, default: "pending", null: false
      t.string :code_url
      t.string :playable_url
      t.string :screenshot_url
      t.decimal :hours, precision: 8, scale: 2, default: 0
      t.decimal :approved_hours, precision: 8, scale: 2, default: 0
      t.string :airtable_id
      t.datetime :submitted_at
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :projects, :status
    add_index :projects, :airtable_id, unique: true
  end
end
