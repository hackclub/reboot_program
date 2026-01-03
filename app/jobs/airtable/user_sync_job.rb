# Syncs users TO Airtable from the local database.
# Pushes user data for external reporting/management.
class Airtable::UserSyncJob < Airtable::BaseSyncJob
  # @return [String] Airtable table name
  def table_name
    ENV.fetch("AIRTABLE_USERS_TABLE", "Users")
  end

  # @return [ActiveRecord::Relation] all User records
  def records
    User.all
  end

  # Maps User attributes to Airtable fields.
  # @param user [User] the user to map
  # @return [Hash] Airtable field values
  def field_mapping(user)
    {
      "slack_id" => user.slack_id,
      "slack_username" => user.slack_username,
      "email" => user.email,
      "name" => user.first_name,
      "last_name" => user.last_name,
      "age" => calculate_age(user.birthday),
      "balance" => user.balance.to_f,
      "Projects" => user.projects.pluck(:name).join(", ")
    }
  end

  private

  # Calculates age from birthday.
  # @param birthday [Date, nil] the user's birthday
  # @return [Integer, nil] age in years or nil if no birthday
  def calculate_age(birthday)
    return nil if birthday.nil?

    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end
end