# Creates journal_entries table for tracking daily work logs on projects.
class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries do |t|
      t.references :project, null: false, foreign_key: true
      t.date :date
      t.decimal :hours
      t.text :content
      t.string :tools

      t.timestamps
    end
  end
end
