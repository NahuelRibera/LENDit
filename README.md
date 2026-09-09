# LENDit

LENDit is a peer-to-peer rental marketplace. People list items they own and rent them out by the day; people who need something short-term book it instead of buying it. There's no separate lender/borrower account type — every user can list items and request other people's items from the same account, and the app splits that into its own "My lends" / "My borrows" views.

It's a full-stack Rails application, server-rendered with Hotwire, with PostgreSQL handling booking constraints, full-text search, and fuzzy matching.

---

## What you can do

- **Sign up and manage a profile** — email/password auth via `has_secure_password`, avatar upload, password reset through signed, expiring tokens.

- **List an item** — title, description, category, condition, city, daily price, multiple photos with a primary image. Listings move draft → published → paused/archived, with transitions validated (you can't archive a listing with an active booking, for example).

- **Browse and search** — full-text search with a fuzzy fallback, filters, sorting, pagination. Details under [Search](#search).

- **View public profiles** — a user's published listings and rating, without their email.

- **Request a rental by date** — pick a start and end date on a listing. Details under [How the rental flow works](#how-the-rental-flow-works).

- **Manage requests as owner or borrower** — accept, decline, withdraw, cancel — grouped by status with counts, in My lends / My borrows.

- **Message the other party** — one thread per listing and user pair, updated live.

- **Get notified** — in-app notifications for rental events and new messages, with an unread badge.

---

## How the rental flow works

A `Rental` stores the listing, borrower, lender, date range, a price snapshot, a status, and a timestamp per lifecycle event, so the rental page can render an actual timeline instead of inferring one from the current status.

1. A lender publishes a listing. Only `published` listings can be booked.

2. A borrower picks dates. Past start dates and booking your own listing are both rejected.

3. Days and price are calculated. Date ranges are inclusive of both endpoints — **Sep 10 to Sep 12 is 3 rental days**, not 2 — and the daily price and total are snapshotted onto the rental right away.

4. A `pending` request is created and the lender is notified. Several people can have overlapping pending requests on the same item at once; pending requests don't reserve anything.

5. The lender accepts or declines. Accepting reserves the dates and auto-declines any other pending request that overlaps them, each with a reason attached. Declining just notifies the borrower.

6. Once accepted, those dates are blocked for any other rental, and the listing can no longer be archived.

7. `RentalLifecycleSweepJob` moves an accepted rental to `active` on its start date, and an active rental to `completed` the day after it ends. It's meant to run on a schedule; since nothing schedules it in this project yet, My lends / My borrows also trigger it inline so the demo behaves correctly.

8. Either side can back out within limits: a borrower can withdraw a pending request, and either party can cancel an accepted booking as long as it hasn't started yet — once it's active, it runs to completion.

9. The two parties can message each other throughout, in the conversation tied to that listing.

| Status | Meaning | Reserves dates? |
| --- | --- | --- |
| `pending` | Awaiting the owner's decision | No |
| `accepted` | Confirmed | Yes |
| `active` | Rental period has started | Yes |
| `completed` | Rental period has ended | No |
| `declined` | Rejected, or auto-declined by a competing acceptance | No |
| `cancelled` | Withdrawn or cancelled before it started | No |

Each transition is a method on `Rental` (`accept!`, `decline!`, `withdraw!`, `cancel!`, `activate!`, `complete!`) that raises `InvalidTransitionError` if called from the wrong state. Controllers call these and turn the exception into a flash message — they never set `status` directly.

---

## Technical highlights

### Booking concurrency

Two overlapping acceptances can't both succeed. That's enforced at three levels, not one.

A model validation rejects an overlapping request against the database on create. `Rental#accept!` locks the listing row (`with_lock`) before accepting, which also covers the cross-table race of an owner blocking a date range at the same moment someone accepts a request for it. Underneath both, PostgreSQL enforces the invariant directly with a partial exclusion constraint:

```sql
ALTER TABLE rentals
ADD CONSTRAINT rentals_no_overlapping_accepted_active
EXCLUDE USING gist (
  listing_id WITH =,
  daterange(start_date, end_date, '[]') WITH &&
)
WHERE (status IN ('accepted', 'active'))
```

If two acceptances still race past the row lock, this constraint is what actually stops the second write; `accept!` catches the resulting `PG::ExclusionViolation` and turns it into a normal error message instead of a 500. `AvailabilityBlock` carries the same kind of constraint for owner-blocked dates. One test proves this by writing around the model with `update_columns` to confirm it's the database, not the Ruby validation, doing the blocking.

Exclusion constraints have no representation in `schema.rb`, so the app dumps its schema as SQL (`schema_format = :sql`) to keep `db:schema:load` faithful to what the migrations actually built.

### Pricing snapshots

Money is stored as integer cents throughout (`price_cents`, `daily_price_cents`, `total_price_cents`), never as a float. `Listing#price` is just a euros-facing accessor over the cents column.

A rental copies the listing's current daily price when it's created, and computes its total from that snapshot. If the owner changes the listing price afterward, existing bookings keep the price they were requested at.

### Authentication and authorization

Auth is plain Rails, not Devise: `has_secure_password`, a session cookie holding the user id, and a `Current.user` resolved once per request in a `before_action`. Password reset tokens come from `generates_token_for`, expire in 20 minutes, and are invalidated the moment the password changes; the reset endpoint replies identically whether or not the email exists, so it can't be used to enumerate accounts.

Authorization is Pundit — one policy per resource. Listings, rentals, and conversations each define a `Scope`, so their index pages resolve through `policy_scope` instead of hand-rolled filtering:

- **Listings** — anyone can view a published one; only the owner can preview a draft, edit it, or manage its status and images.

- **Rentals** — only the borrower or lender can view one; only the lender can accept or decline.

- **Conversations** — only participants can read or post; `Message` independently validates that the sender is a participant, as a second check.

- **Users** — profiles are public; only you can edit your own.

Public profiles never render an email address, and listings store a city rather than a street address — exact pickup details are something the two people work out in the conversation, not something the marketplace publishes.

### Search

`ListingSearch` is a small query object, kept out of the controller, that runs full-text search with a fuzzy fallback. Listings carry a generated, indexed `tsvector` column (title weighted above description), queried with `plainto_tsquery`. If that returns nothing, it falls back to `pg_trgm` word-similarity matching against the title, which tolerates a typo in one word of a longer title instead of being diluted by the rest of the string. Results rank by `ts_rank` or by similarity score, depending on which path matched.

On top of that: filters for category, condition, city, price range, and minimum owner rating; sorting by relevance, newest, price, or rating; pagination via Pagy.

### Real-time messaging and notifications

A `Conversation` is scoped to one listing and one (ordered) pair of users, enforced by a unique index and a check constraint — so messaging an owner about an item always lands in the same thread, no matter how many times you rent from them. Messages broadcast over Turbo Streams on create; since a broadcast renders once for everyone watching, a small Stimulus controller classifies each bubble as mine or theirs on the client and keeps the thread scrolled down. Unread state lives per user in `conversation_reads`, and the navbar badge count is computed in a single SQL query rather than loading every conversation into Ruby.

Rental events — requested, accepted, declined, cancelled, activated, completed — and new messages all create in-app notifications through one `Notifications::Notifier.notify` call site, invoked from the model code that already owns each event. That keeps "who gets told what" next to the thing that causes it, instead of scattered across controllers.

### Reputation

Users carry `ratings_avg` and `ratings_count`, shown on cards, profiles, and listing pages, and usable as a search filter and sort. There's no review-writing flow yet — the fields exist and the read paths work, but nothing in the app writes to them. See [Scope and future work](#scope-and-future-work).

---

## Tech stack

| Layer | Choice |
| --- | --- |
| Language | Ruby 3.3.7 |
| Framework | Rails 7.1 |
| Database | PostgreSQL, with `btree_gist`, `pg_trgm`, `citext` |
| Views | Server-rendered ERB |
| Frontend | Hotwire — Turbo Drive, Turbo Streams, Stimulus, via import maps |
| Real-time | Action Cable (async in development, Redis in production config) |
| Files | Active Storage, local disk, libvips variants |
| Background jobs | Active Job (`RentalLifecycleSweepJob`, mail delivery) |
| Authentication | `has_secure_password` + bcrypt |
| Authorization | Pundit |
| Pagination | Pagy |
| Styling | Hand-written CSS, no framework |
| Testing | Minitest with fixtures |

---

## Domain model

```text
User
 ├── has_many listings                    (restricted destroy)
 ├── has_many rentals_as_lender           ─┐
 ├── has_many rentals_as_borrower         ─┴─ same Rental table, two roles
 ├── has_many sent_messages
 ├── has_many notifications               (as recipient)
 └── has_one_attached avatar

Listing
 ├── belongs_to user (owner) + category
 ├── has_many listing_images  ──> has_one_attached file
 ├── has_many rentals                     (restricted destroy)
 ├── has_many availability_blocks
 └── generated tsvector column for search

Rental                                    Conversation
 ├── belongs_to listing                    ├── belongs_to listing
 ├── belongs_to borrower (User)            ├── belongs_to user_one / user_two (ordered)
 ├── belongs_to lender (User)              ├── has_many messages
 ├── status + per-event timestamps         └── has_many conversation_reads
 └── daily/total price snapshot

Notification ──> polymorphic notifiable (Rental | Message)
```

Delete behavior is chosen per relationship, not defaulted: users, categories, and listings can't be deleted while they still have listings, rentals, or messages attached (`RESTRICT`); records that only exist as children — images, availability blocks, read markers — cascade with their parent.

---

## Frontend approach

ERB views, Turbo Drive for navigation, Turbo Streams for live updates, and Stimulus for everything that needs a little client-side behavior: the booking price preview, chat scrolling and bubble classification, the image gallery, dropdowns, the mobile menu, the filter panel. It ships via import maps — no bundler, no `package.json`, no build step.

Styling is hand-written CSS on a small design-token file. The teal-and-mint palette is sampled from the original LENDit logo, and the rest of the palette is derived from those two colors. Images go through Active Storage with libvips variants, sized per context and validated for type and size.

---

## Running the project locally

**Requirements**

- Ruby 3.3.7 (`.ruby-version`)
- PostgreSQL
- libvips, for image variants (`brew install vips` on macOS)

No environment variables are needed locally. Action Cable uses the async adapter in development, so Redis isn't required either.

```bash
git clone https://github.com/NahuelRibera/LENDit.git
cd LENDit
bundle install
bin/rails db:prepare   # creates the db, loads db/structure.sql
bin/rails db:seed      # marketplace categories
bin/rails server
```

Open http://localhost:3000 and sign up.

> **PostgreSQL version:** `db/structure.sql` was dumped with `pg_dump` 17 and includes a `SET transaction_timeout` line that only PG 17+ understands. On an older server, run `bin/rails db:create db:migrate` instead, or just delete that one line before `db:prepare`.

Password reset mail uses `:test` delivery in development — nothing is actually sent, check the log or console output for the delivery instead of an inbox.

---

## Demo data

`db/seeds.rb` only creates the 8 marketplace categories — no demo users, listings, or credentials. Sign up and create your own; register two accounts if you want to see both sides at once, listing from one and booking from the other.

Fixtures with rentals in various states exist under `test/fixtures/` for the test suite, but aren't loaded into development.

---

## Running tests

```bash
bin/rails test
```

157 tests, Minitest with fixtures, run in parallel. Capybara and Selenium are installed but there are no system tests yet, so there's no separate `test:system` run.

Weighted toward business logic:

- **Rental lifecycle** — every transition and its guards, inclusive day counting, price snapshotting, `requested_at` set server-side.

- **Booking conflicts** — overlapping pending requests allowed, overlapping accepted rentals rejected, auto-decline on acceptance, availability blocks, and a test proving the database exclusion constraint itself is what blocks a conflict.

- **Authorization** — a policy test per resource, plus controller tests attempting to reach other users' rentals, conversations, and draft listings by id.

- **Messaging** — one conversation per listing and pair regardless of who starts it, non-participants blocked at both the policy and model level, unread state.

- **Search** — full-text matching, the trigram fallback, each filter, each sort, pagination.

- **Auth** — sign-in/out, registration failures, email normalization, the full password-reset token lifecycle.

- **Notifications** — who gets notified for each event, and that nobody is notified about their own action.

---

## Project structure

| Path | What's there |
| --- | --- |
| `app/models/rental.rb` | The rental state machine, locking, conflict handling |
| `app/models/listing_search.rb` | Full-text + trigram search |
| `app/models/conversation.rb` | Normalized pairs, unread state |
| `app/policies/` | Pundit policies and scopes |
| `app/javascript/controllers/` | Stimulus controllers |
| `db/migrate/20260101000006_create_rentals.rb` | The exclusion constraint |
| `db/structure.sql` | Schema of record |
| `test/models/rental_test.rb` | The clearest description of the booking rules |

---

## Product and engineering decisions

A few choices worth calling out on their own, beyond what's covered above:

- **One account, both roles.** No lender onboarding, no separate seller dashboard — `Rental` just has a `borrower` and a `lender`, and the UI splits by role.

- **Discovery hides your own listings.** The homepage, browse page, and category pages exclude the current user's own items, because those are borrowing contexts. Your public profile and My products still show them.

- **Conversations follow the (listing, pair), not the rental.** Renting the same item from someone three times stays one thread, not three.

The concurrency, pricing, and inclusive-date decisions are covered in [Technical highlights](#technical-highlights) and [How the rental flow works](#how-the-rental-flow-works).

---

## Scope and future work

The following features are outside the current scope:

- **Payments.** Rentals carry prices and totals, but no money moves — no escrow, payouts, or refunds.

- **Reviews.** Rating fields and their read paths exist; nothing writes to them yet. The plan is reviews tied to a `completed` rental, one per side, rather than free-standing reviews.

- **Identity verification and deposits.**

- **Owner availability calendar UI.** `AvailabilityBlock`, its exclusion constraint, and its tests are in place; there's no screen for creating one yet.

- **Maps and geolocation.** Search matches on city name, not radius.

- **Production deployment.** A Dockerfile exists; there's no hosting, scheduler, or real email delivery configured.
