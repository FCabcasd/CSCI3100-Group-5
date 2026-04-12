# CUHK Venue & Equipment Booking SaaS

A multi-tenant venue and equipment booking system for CUHK student societies. Each department acts as an independent tenant, managing its own venues and equipment with approval workflows, real-time notifications, and AI-powered consultation.

## Live Demo

**Walking Skeleton URL:** https://group5app-e244cbe44724.herokuapp.com/

## Team Information (Group 5)

| SID | Name | GitHub |
|-----|------|--------|
| 1155192617 | Hung Hei Chit | [FCabcasd](https://github.com/FCabcasd) |
| 1155173771 | Zhiyu Wang | [Oliver-Wo](https://github.com/Oliver-Wo) |
| 1155264327 | Geyu Liu | [LGY](https://github.com/LGY) |
| 1155213219 | Cheung Ka Tsun | |
| 1155212179 | Pang Enoch | [PangEnoch](https://github.com/PangEnoch) |

## Tech Stack

- **Backend:** Ruby on Rails 8.1 (API mode)
- **Auth:** BCrypt + JWT (HS256)
- **Database:** SQLite (dev/test), PostgreSQL (production)
- **Background Jobs:** Solid Queue
- **Real-Time:** ActionCable (Solid Cable)
- **AI:** OpenAI GPT-3.5 Turbo
- **Email:** Action Mailer with async delivery
- **Security:** Rack::Attack (rate limiting), Rack::Cors
- **Testing:** RSpec, Cucumber, SimpleCov, FactoryBot
- **Deployment:** Docker + Heroku

## Setup

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Run the server
bin/rails server

# Run tests
bundle exec rspec
bundle exec cucumber
```

## API Endpoints

### Authentication
- `POST /api/auth/register` — Register new user
- `POST /api/auth/login` — Login (returns JWT)
- `POST /api/auth/refresh` — Refresh access token
- `GET /api/auth/me` — Current user profile

### Bookings
- `GET /api/bookings` — List my bookings (paginated)
- `POST /api/bookings` — Create booking
- `GET /api/bookings/:id` — Booking details
- `POST /api/bookings/:id/cancel` — Cancel booking
- `POST /api/bookings/:id/confirm` — Confirm booking (admin)
- `POST /api/bookings/:id/check_in` — On-site check-in
- `POST /api/bookings/create_recurring` — Create recurring booking

### Venues
- `GET /api/venues` — List venues (paginated)
- `GET /api/venues/:id` — Venue details
- `GET /api/venues/search?q=` — Fuzzy search venues
- `POST /api/venues` — Create venue (admin)
- `PATCH /api/venues/:id` — Update venue (admin)
- `DELETE /api/venues/:id` — Soft-delete venue (admin)

### Equipment
- `GET /api/equipment` — List equipment (paginated)
- `GET /api/equipment/:id` — Equipment details
- `GET /api/equipment/search?q=` — Fuzzy search equipment
- `POST /api/equipment` — Create equipment (admin)
- `PATCH /api/equipment/:id` — Update equipment (admin)
- `DELETE /api/equipment/:id` — Soft-delete equipment (admin)

### Admin
- `GET /api/admin/users` — List users
- `POST /api/admin/users/:id/suspend` — Suspend user
- `DELETE /api/admin/users/:id` — Delete user
- `POST /api/admin/bookings/:id/force_cancel` — Emergency cancel (no penalty)

### AI Consultant
- `GET /api/ai/status` — Check AI availability
- `POST /api/ai/ask` — Ask booking questions
- `POST /api/ai/recommend-venues` — Get venue recommendations
- `POST /api/ai/check-conflicts` — Check time conflicts

### Analytics
- `GET /api/analytics/bookings/stats` — Booking statistics (admin)
- `GET /api/analytics/venues/usage` — Venue usage report (admin)
- `GET /api/analytics/peak-times` — Peak time analysis (admin)

### Maps
- `GET /api/venues/:id/map` — Google Maps URL for venue

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY_BASE` | JWT signing secret | Yes (production) |
| `OPENAI_API_KEY` | OpenAI API key for AI features | No (graceful degradation) |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | No (defaults localhost) |
| `MAILER_SENDER` | Default email sender address | No |
| `DATABASE_URL` | PostgreSQL connection URL | Yes (production) |

## Testing

```bash
# Run all RSpec tests
bundle exec rspec

# Run Cucumber acceptance tests
bundle exec cucumber

# Check test coverage (opens coverage/index.html)
open coverage/index.html
```

### Latest Results

| Suite | Total | Passed | Failed | Status |
|-------|-------|--------|--------|--------|
| RSpec | 212 examples | 212 | 0 | ✅ All passed |
| Cucumber | 23 scenarios (147 steps) | 23 | 0 | ✅ All passed |

### Coverage

| Metric | Result | Target |
|--------|--------|--------|
| Line Coverage | **93.7%** (548/585) | >80% |
| Branch Coverage | **82.4%** (136/165) | >65% |

### Key Coverage Highlights

| Layer | Coverage |
|-------|----------|
| Models (all) | 100% |
| Services (all) | 100% |
| Controllers | 86–100% |
| Mailers | 100% |
| Channels | 75–100% |
