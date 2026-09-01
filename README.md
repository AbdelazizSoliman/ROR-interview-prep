# Ruby & Rails Interview Prep

Phase 0 establishes the application foundation with Ruby, Rails, PostgreSQL,
Hotwire, Tailwind CSS, RSpec, and FactoryBot. Domain features are intentionally
out of scope for this phase.

## Requirements

- Ruby 3.4.x
- PostgreSQL 16 or newer
- Bundler
- Node.js 20 or newer (optional with the current importmap and standalone
  Tailwind setup, but useful for development tooling)

## Setup

Install dependencies and prepare the development and test databases:

```sh
bin/setup
```

By default, PostgreSQL connections use the local Unix socket and your operating
system user. For a TCP or password-protected PostgreSQL installation, set the
standard variables before running setup:

```sh
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=your_password
```

You can also provide `DATABASE_URL` where supported by Rails.

## Development

Start Rails and the Tailwind watcher together:

```sh
bin/dev
```

Then open <http://localhost:3000>. The health endpoint is available at
<http://localhost:3000/up>.

## Verification

Run the test suite and build the CSS bundle:

```sh
bundle exec rspec
bin/rails tailwindcss:build
```

Additional quality checks are available through:

```sh
bin/ci
```

## Question bank

Question-bank source files live under `db/question_bank/`. Import all YAML files with:

```sh
bin/rails question_bank:import
```

Each question has a globally unique `stable_key` such as
`active_record.eager_loading.includes_preload_eager_load`. Stable keys are durable
identities: do not derive them from database IDs or change them after publication.
The importer is idempotent, updates existing records by stable key, synchronizes
concepts by their YAML order, and fails the whole transaction when source content
or follow-up references are invalid.
