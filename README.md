# CUHK Venue & Equipment Booking SaaS

A multi-tenant venue and equipment booking system for CUHK student societies. Each department acts as an independent tenant, managing its own venues and equipment with approval workflows, real-time notifications, and AI-powered consultation.

## Live Demo

**Deployed URL:** https://cuhk-venue-booking-aeee75bcd129.herokuapp.com/

## Team Information (Group 5)

| SID | Name | GitHub |
|-----|------|--------|
| 1155192617 | Hung Hei Chit | [quo-dt](https://github.com/quo-dt) |
| 1155173771 | Zhiyu Wang | [Oliver-Wo](https://github.com/Oliver-Wo) |
| 1155264327 | Geyu Liu | [LGY](https://github.com/LGY) |
| 1155213219 | Cheung Ka Tsun | [FCabcasd](https://github.com/FCabcasd) |
| 1155212179 | Pang Enoch | [PangEnoch](https://github.com/PangEnoch) |

## Tech Stack

- **Backend:** Ruby on Rails 8.1 (API mode)
- **Auth:** BCrypt + JWT (HS256)
- **Database:** SQLite (dev/test), PostgreSQL (production)
- **Background Jobs:** ActiveJob (async adapter)
- **Real-Time:** ActionCable (WebSockets)
- **AI:** Google Gemini (gemini-2.5-flash-lite)
- **Email:** Action Mailer + Resend SMTP
- **Maps:** Google Maps integration
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
| `GEMINI_API_KEY` | Google Gemini API key for AI features | No (graceful degradation) |
| `RESEND_API_KEY` | Resend API key for email delivery | No |
| `SMTP_FROM` | Default email sender address | No |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | No (defaults localhost) |
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
| RSpec | 217 examples | 217 | 0 | ✅ All passed |
| Cucumber | 23 scenarios (147 steps) | 23 | 0 | ✅ All passed |

### Coverage

| Metric | Result | Target |
|--------|--------|--------|
| Line Coverage | **82.16%** (617/751) | >80% |
| Branch Coverage | **72.2%** (148/205) | >65% |

### Key Coverage Highlights

| Layer | Coverage |
|-------|----------|
| Models (all) | 100% |
| Services (all) | 100% |
| Controllers | 86–100% |
| Mailers | 100% |
| Channels | 75–100% |

## Feature Ownership
| Feature | Primary Developer | Secondary Developer | Notes |
|---------|-------------------|---------------------|-------|
| User Auth and Roles | Zhiyu Wang, Hung Hei Chit |  Pang Enoch, Cheung Ka Tsun | Uses JWT token and bcrypt |
| Venue Calendar |  Zhiyu Wang | x | Uses FullCalendar API |
| conflict detection logic | Zhiyu Wang, Hung Hei Chit | x | check and reject immediately if time clashes during registration |
| Avoid cross-tenant complexity | Zhiyu Wang, Hung Hei Chit  | x | Tenant-scoped venues/equipment in database |
| Cancellation and Point deduction system | Zhiyu Wang, Hung Hei Chit | x |  |
| optimistic locking | Zhiyu Wang | Hung Hei Chit | Each bookings is pending and waiting for admin to confirm |
| Background jobs | Cheung Ka Tsun | x | Run on ActiveJob and ActionCable |
| Registration Data Analytics | Geyu Liu  | x | Interactive Dashboards |
| Search Engine and filter | Zhiyu Wang | Cheung Ka Tsun | Uses Fuzzy Search | 
| Google Maps | Geyu Liu | x | Uses GoogleMap API |
| Email notification | Cheung Ka Tsun | x | Uses Action Mailer with Resend SMTP | 
| AI assistant | Cheung Ka Tsun | x | Uses Gemini API |
