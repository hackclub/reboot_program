class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :airtable_id
      t.string :projects
      t.string :slack_id
      t.string :slack_username
      t.date :synced_at

      t.timestamps
    end
  end
end
