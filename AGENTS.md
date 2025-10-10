# Repository Guidelines

## Project Structure & Module Organization
- `lib/` – Gem source. Core modules live under `lib/workato/{cli,connector,extension,testing,types,utilities,web}`. Entrypoint: `lib/workato-connector-sdk.rb`.
- `exe/workato` – CLI executable.
- `spec/` – RSpec tests (`support/`, `fixtures/`, `examples/`). VCR cassettes: `spec/fixtures/vcr_cassettes`.
- `templates/` – Code generator templates. `sorbet/` – Sorbet config and RBI files.

## Build, Test, and Development Commands
- Setup: `bundle install`
- Lint: `bundle exec rubocop`
- Type check: `bundle exec srb tc`
- Update RBIs: `bundle exec tapioca gems`
- Test: `bundle exec rspec` (single spec: `bundle exec rspec spec/path_spec.rb:42`)
- Coverage: SimpleCov runs automatically; CI enforces ≥90% suite and ≥85% per‑file coverage.
- Build gem: `gem build workato-connector-sdk.gemspec`
- CLI locally: `bundle exec exe/workato help`

## Coding Style & Naming Conventions
- Ruby 2.7; 2‑space indentation; single quotes; `# frozen_string_literal: true` at top.
- Files: `snake_case.rb`. Classes/Modules: `CamelCase` under `Workato::...` namespaces.
- Keep methods small (<30 lines) and focused; prefer clear, explicit code over cleverness.
- Add Sorbet sigil (`# typed: strict` or `# typed: true`) to new files; keep RBI in sync via Tapioca.

## Testing Guidelines
- Framework: RSpec with WebMock + VCR (use `:vcr` metadata where HTTP is involved).
- Store cassettes in `spec/fixtures/vcr_cassettes`; scrub secrets and keep fixtures minimal.
- Name specs `*_spec.rb` and mirror code paths, e.g., `lib/workato/.../request.rb` → `spec/workato/.../request_spec.rb`.
- New/changed code must include tests and maintain coverage thresholds.

## Commit & Pull Request Guidelines
- Commits: prefer Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`). Release commits follow `X.Y.Z - summary` as in history.
- PRs: clear description and rationale, linked issues, tests added/updated, docs/CHANGELOG updated when user‑facing.
- CI must pass (Rubocop, Sorbet, RSpec, coverage). Keep diffs small and focused.

## Security & Configuration Tips
- Never commit credentials or tokens. Record external calls with VCR and redact sensitive headers.
- For CI/local parity, run: `bundle exec rubocop && bundle exec srb tc && bundle exec rspec` before pushing.

