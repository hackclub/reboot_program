class AddMediaUrlsToJournalEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :journal_entries, :media_urls, :jsonb
  end
end
