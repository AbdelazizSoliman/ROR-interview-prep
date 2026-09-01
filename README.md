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

## Evaluation mode

Answer evaluation uses the deterministic phrase evaluator by default. To opt
into the OpenAI adapter explicitly, set these environment variables (never
commit the key):

```sh
export INTERVIEW_EVALUATOR=ai
export OPENAI_API_KEY=your_key
export OPENAI_EVALUATION_MODEL=gpt-5.6-luna
export OPENAI_EVALUATION_TIMEOUT=30
```

Set `INTERVIEW_EVALUATOR=deterministic` for local development without an API
key. AI evaluations use the configured model and persist only normalized
feedback and evaluator metadata, not prompts or raw provider responses.

## Review scheduling

Continuing an evaluated question creates or updates its per-user
`ReviewSchedule`. Core Mid practice seeds schedules; Daily Review selects up to
10 active questions whose `next_review_at` is due, ordered by oldest due date,
weakest score, then deterministic question order. Scheduling uses deterministic
day intervals; mastery and readiness metrics are not implemented yet.
Intervals are intentionally uncapped in Phase 6; repeated score-5 reviews grow
14 → 35 → 88 → 220 → ... until later mastery tuning introduces a product limit.

## Question bank

Question-bank source files live under `db/question_bank/`. Import all YAML files with:

```sh
bin/rails question_bank:import
```

Each question has a globally unique `stable_key` such as
`active_record.eager_loading.includes_preload_eager_load`. Stable keys are durable
identities: do not derive them from database IDs or change them after publication.
QuestionConcept records have stable keys unique within each question; do not
change them after publication. The importer is idempotent, updates existing
records by stable key, synchronizes concepts by their stable keys, and fails the whole transaction when source content
or follow-up references are invalid.
