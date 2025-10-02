# workato-connector-sdk Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-09-29

## Active Technologies
- Ruby >= 2.7.6 (per gemspec requirement) + Thor (CLI framework ~> 1.0), Ruby parser/AST libraries (Ripper or Parser gem for syntax validation), Sorbet runtime (~> 0.5 for type safety), ActiveSupport (>= 5.2, < 7.1) (001-add-workato-validate)

## Project Structure
```
src/
tests/
```

## Commands
```bash
# Validate connector code
workato validate [--connector=PATH] [--output=FILE] [--verbose]

# Execute connector blocks
workato exec <PATH> [--connector=PATH] [--settings=PATH]

# Create new connector
workato new <PATH>

# Push connector to Workato
workato push

# OAuth2 authorization
workato oauth2

# Edit encrypted settings
workato edit <PATH>
```

## Code Style
Ruby >= 2.7.6 (per gemspec requirement): Follow standard conventions

## Recent Changes
- 2025-09-30: Added `workato validate` command with 8 validators, 25+ validation rules, JSON/human output, exit codes (0/1/2)
- 2025-09-30: Added dev container (.devcontainer/) for reproducible Ruby 2.7.8 environment
- 2025-09-30: Updated constitution (v1.1.0) with Principle VIII: Stable Development Environments
- 001-add-workato-validate: Added Ruby >= 2.7.6 (per gemspec requirement) + Thor (CLI framework ~> 1.0), Ruby parser/AST libraries (Ripper or Parser gem for syntax validation), Sorbet runtime (~> 0.5 for type safety), ActiveSupport (>= 5.2, < 7.1)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->