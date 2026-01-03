# Stores the Hack Club Auth token for PII autofill in YSWS submissions.
class AddHcaTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :hca_token, :string
    add_column :users, :hca_token_expires_at, :datetime
  end
end
