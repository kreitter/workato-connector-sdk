<!--
Sync Impact Report:
Version Change: 1.0.0 → 1.1.0 (Added Principle VIII)
Modified Principles: Added new principle on stable development environments
Added Sections:
  - Core Principles (8 principles, added VIII. Stable Development Environments)
  - Quality Standards
  - User Experience Standards
  - Governance
Removed Sections: N/A
Templates Status:
  ✅ .specify/templates/plan-template.md - References constitution check (line 47-50)
  ✅ .specify/templates/spec-template.md - No constitution-specific updates needed
  ✅ .specify/templates/tasks-template.md - TDD enforcement aligns with principle III
  ⚠ .specify/templates/agent-file-template.md - Review recommended for testing guidance
Follow-up Actions Taken:
  - Created .devcontainer/ for reproducible development environment
  - Created .ruby-version file to lock Ruby 2.7.8
  - Documented dev container rationale in .devcontainer/README.md
-->

# Workato Connector SDK Constitution

## Core Principles

### I. Backward Compatibility (NON-NEGOTIABLE)
The SDK MUST maintain backward compatibility across MINOR and PATCH versions. Breaking changes are only permitted in MAJOR version releases and MUST be documented with migration guides. Existing connector code built against v1.x MUST continue to function without modification in v1.y where y > x.

**Rationale**: Connector developers rely on SDK stability. Breaking changes force coordination across hundreds of community connectors.

### II. DSL Parity with Platform
Every DSL method, connector feature, and behavior available in the Workato platform MUST have an equivalent implementation in the SDK. The SDK is the source of truth for connector behavior outside the platform.

**Rationale**: Developers must trust that local testing accurately predicts production behavior. Gaps between SDK and platform create false confidence and deployment failures.

### III. Test-First Development (NON-NEGOTIABLE)
- All new features MUST have RSpec tests written before implementation
- Tests MUST fail initially, then pass after implementation (Red-Green-Refactor)
- Code coverage MUST NOT decrease; new code MUST maintain ≥90% coverage
- All example connectors in `spec/examples/` MUST have corresponding test files
- VCR cassettes MUST be used for all HTTP interactions in tests

**Rationale**: The SDK is a testing tool for connectors. If the SDK itself lacks testing discipline, it cannot enforce quality standards for connector developers.

### IV. CLI Ergonomics and Consistency
- Every CLI command MUST follow the pattern: `workato <command> [options]`
- All commands MUST support `--help` with clear examples
- Error messages MUST be actionable (what went wrong, how to fix it)
- Output MUST support both human-readable and JSON formats
- Verbose mode (`--verbose`) MUST log all HTTP requests for debugging
- All file path options MUST accept both absolute and relative paths

**Rationale**: CLI is the primary interface for connector development. Inconsistent or unclear commands increase friction and reduce adoption.

### V. Performance Boundaries
- CLI command startup MUST complete within 2 seconds for common operations
- Test execution MUST run at near-native RSpec speed (SDK overhead <10%)
- VCR cassette encryption/decryption MUST NOT add >50ms per test file
- Memory consumption during connector execution MUST NOT exceed 512MB for typical connectors

**Rationale**: Slow tooling breaks developer flow. Performance regressions accumulate and are difficult to reverse.

### VI. Security by Default
- Encrypted settings (`.yaml.enc`) MUST be the default in all documentation
- Plain text credentials MUST trigger warnings in CLI output
- Master keys MUST NEVER be committed (enforce via `.gitignore` templates)
- VCR cassettes MUST support encryption for sensitive API responses
- OAuth2 tokens MUST be automatically refreshed and re-encrypted

**Rationale**: Connector developers handle sensitive API credentials. SDK must make secure practices the path of least resistance.

### VII. Documentation as Code
- Every public API method MUST have YARD documentation
- CLI commands MUST maintain examples in both `--help` output and README.md
- Breaking changes MUST include migration guides in CHANGELOG.md
- Example connectors MUST represent real-world authentication patterns
- README.md getting-started guide MUST be executable by new users in <15 minutes

**Rationale**: Poor documentation creates support burden and reduces community contributions. Documentation drift indicates architectural misalignment.

### VIII. Stable Development Environments (NON-NEGOTIABLE)
- All SDK development MUST occur in isolated, reproducible environments (dev containers, Docker, or equivalent)
- Native gem compilation MUST NOT require manual system-level library installations
- Development environment configuration MUST match CI environment (Ruby version, OS, dependencies)
- `.ruby-version` file MUST be maintained to lock Ruby version across all environments
- No changes to user's global system Ruby, system libraries, or compiler toolchain
- Dev container MUST be the default development method, documented in `.devcontainer/README.md`
- Onboarding time from clone to working environment MUST be <5 minutes (excluding Docker image download)

**Rationale**: SDK depends on native extensions (charlock_holmes) requiring specific C++ compilers and ICU libraries. Incompatibilities between macOS (especially Apple Silicon), different Ruby versions, and system compilers create setup friction and "works on my machine" problems. Dev containers ensure all contributors and CI share identical environments, eliminating dependency conflicts and reducing onboarding time.

## Quality Standards

### Code Quality Requirements
- **Ruby Style**: Follow Rubocop rules defined in `.rubocop.yml` (no exceptions without team consensus)
- **Type Safety**: Sorbet type annotations required for all public methods in `lib/workato/connector/sdk/`
- **Complexity**: Cyclomatic complexity MUST NOT exceed 15 per method; ABC metric MUST NOT exceed 20
- **Naming**: DSL methods MUST match Workato platform naming exactly (e.g., `after_error_response`, `request_format_www_form_urlencoded`)
- **Dependencies**: New gem dependencies MUST be justified (size, security, maintenance), pinned with pessimistic versioning

### Testing Standards
- **Unit Tests**: Cover edge cases, error conditions, and type coercions
- **Integration Tests**: Verify end-to-end CLI workflows (exec, oauth2, push)
- **Example Coverage**: Every DSL feature MUST have a working example in `spec/examples/`
- **Regression Tests**: Bug fixes MUST include a test that would have caught the bug
- **Test Isolation**: Tests MUST NOT depend on execution order; parallel execution MUST pass

### Code Review Requirements
- All PRs MUST pass CI (tests, Rubocop, Sorbet type checks)
- Breaking changes MUST be flagged in PR title with `[BREAKING]`
- New CLI commands MUST include help text and integration test
- Security-sensitive code (encryption, token handling) MUST have dedicated security review

## User Experience Standards

### CLI UX Principles
- **Progressive Disclosure**: Basic usage MUST work with minimal flags; advanced options available via `--help`
- **Fail Fast**: Invalid configurations MUST error immediately with specific fix instructions
- **Sensible Defaults**: `settings.yaml.enc` auto-detected; `connector.rb` assumed as default path
- **Interactivity When Needed**: Token refresh MUST prompt user; OAuth2 MUST open browser automatically
- **Consistency Across Commands**: All commands MUST use same flag names (`--connector`, `--settings`, `--key`)

### Error Message Standards
- Format: `ERROR: [what failed]. [why it failed]. [how to fix it].`
- Example: `ERROR: Connection test failed. API returned 401 Unauthorized. Check your API key in settings.yaml.enc.`
- MUST include file paths, line numbers, or configuration keys when relevant
- MUST link to docs for complex issues (e.g., OAuth2 setup)

### Output Format Standards
- **Default**: Human-readable with color (via `colorize` or similar)
- **JSON Mode**: `--output=file.json` for programmatic consumption
- **Verbose Mode**: `--verbose` shows HTTP request/response details
- **Progress Indicators**: Long operations (>2s) MUST show progress bar

## Governance

### Amendment Process
1. Proposal MUST be documented in GitHub issue with rationale
2. Team discussion MUST reach consensus (no vetoes on principle changes)
3. Amendment MUST include migration plan for affected code
4. Constitution version MUST be bumped per semantic versioning:
   - **MAJOR**: Principle removal or backward-incompatible governance change
   - **MINOR**: New principle added or existing principle materially expanded
   - **PATCH**: Clarifications, wording improvements, non-semantic updates
5. All dependent templates (plan, spec, tasks) MUST be reviewed for consistency
6. CHANGELOG.md MUST document constitutional changes

### Compliance and Enforcement
- All PRs MUST verify compliance with applicable principles
- CI MUST enforce: test coverage ≥90%, Rubocop passing, Sorbet type checks clean
- Performance regression tests MUST run on `main` branch (alert if >10% slowdown)
- Security audits MUST run quarterly on dependencies (`bundle audit`)
- Constitution review MUST occur before each MAJOR version release

### Deviation Approval
- Deviations MUST be documented in PR description with justification
- Temporary deviations MUST include GitHub issue for remediation
- Permanent deviations MUST propose constitution amendment
- Security or backward compatibility deviations require unanimous team approval

### Living Document
- Constitution MUST be reviewed quarterly for relevance
- Outdated principles MUST be updated or removed (with MAJOR version bump if removed)
- New patterns emerging in >3 PRs MUST be evaluated for principle codification

**Version**: 1.1.0 | **Ratified**: 2025-01-29 | **Last Amended**: 2025-09-30