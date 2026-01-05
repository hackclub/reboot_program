# AGENTS.md

## Commands
- **Server**: `bin/rails server` or `docker compose up`
- **Console**: `bin/rails console`
- **Tests**: `bin/rails test` (single: `bin/rails test test/models/user_test.rb` or `bin/rails test test/models/user_test.rb:42`)
- **Lint**: `bundle exec rubocop` (autofix: `bundle exec rubocop -a`)
- **DB setup**: `bin/rails db:create db:migrate`

## Architecture
Rails 8 API app with PostgreSQL. Uses Solid Queue/Cache/Cable for background jobs.
- `app/models/` — ActiveRecord models (User, Project, ShopItem, ShopOrder)
- `app/controllers/api/` — JSON API endpoints
- `app/services/` — Service objects (HackClubAuthService, JwtService)
- `app/jobs/` — Background jobs, namespaced (e.g., `Airtable::YswsSubmissionJob`)
- External integrations: Airtable (norairrecord gem), Hack Club Auth (omniauth-hack_club)

## Code Style
Uses rubocop-rails-omakase. Follow Rails conventions:
- snake_case for methods/variables, CamelCase for classes
- YARD-style docstrings (`@param`, `@return`) for complex methods
- Service objects for external API calls; jobs for async work
- Use `with_indifferent_access` for hashes with mixed symbol/string keys
- Error handling: log with `Rails.logger`, re-raise for retryable job errors
