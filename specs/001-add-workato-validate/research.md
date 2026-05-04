# Research: Workato Validate Command

**Feature**: Workato Validate Command
**Date**: 2025-01-29
**Status**: Complete

## Research Questions & Findings

### 1. Ruby AST Parsing for Connector Validation

**Question**: What's the best approach for parsing Ruby connector code to extract structure and validate DSL usage?

**Decision**: Use Ruby's built-in `Ripper` library for AST parsing

**Rationale**:
- **Ripper** (Ruby stdlib): Provides low-level AST access, no external dependencies, battle-tested since Ruby 1.9
- **Parser gem** (alternative): More features but adds external dependency; overkill for our needs
- Ripper provides sufficient hooks for:
  - Syntax validation via `Ripper.sexp(code)` (returns nil on syntax errors)
  - AST traversal to find connector hash structure
  - Line number tracking for error reporting

**Alternatives Considered**:
- `Parser` gem: Rejected due to unnecessary external dependency (constitutional principle: minimize deps)
- `RuboCop::AST`: Rejected as it requires RuboCop as runtime dependency (currently dev-only)
- `eval` + introspection: Rejected due to security concerns (executes arbitrary code)

**Implementation Notes**:
- Use `Ripper::SexpBuilder` or `Ripper::SexpBuilderPP` for readable S-expressions
- Extract connector hash by finding `{` at top level after any requires
- Cache parsed AST to avoid re-parsing for multiple validators

---

### 2. Validation Rule Architecture

**Question**: How should validation rules be organized to maintain <15 cyclomatic complexity and enable easy extension?

**Decision**: Strategy pattern with isolated validator classes

**Rationale**:
- Each validator class handles one concern (single responsibility)
- Base class provides common functionality (file I/O, finding reporting)
- Validators are stateless and independently testable
- New rules can be added without modifying existing validators

**Architecture**:
```ruby
# Base class
class BaseValidator
  def validate(connector_ast, connector_hash) -> [Finding]
  def report_finding(rule_name, severity, message, line_number, fix)
end

# Example concrete validator
class SyntaxValidator < BaseValidator
  def validate(code_string) -> [Finding]
    # Uses Ripper to check syntax
  end
end
```

**Alternatives Considered**:
- Single monolithic validator: Rejected (violates complexity limits, hard to test)
- Rule engine with DSL: Rejected (over-engineering for 25 rules)
- Visitor pattern on AST: Rejected (unnecessary complexity, multiple passes needed anyway)

---

### 3. DSL Pattern Detection

**Question**: How to detect deprecated DSL patterns and suggest modern alternatives?

**Decision**: Maintain versioned DSL deprecation registry as Ruby hash

**Rationale**:
- Centralized deprecation knowledge
- Easy to update as DSL evolves
- Can reference Workato platform changelog
- Supports versioned messages ("deprecated since X.Y.Z")

**Example Registry Structure**:
```ruby
DEPRECATED_PATTERNS = {
  'after_error_response' => {
    deprecated_since: '1.0.0',
    replacement: 'error_handler',
    message: 'after_error_response is deprecated. Use error_handler instead.',
    severity: :warning
  },
  'request_format_www_form_urlencoded' => {
    deprecated_since: nil, # Not actually deprecated, kept for reference
    replacement: nil,
    severity: :info
  }
}
```

**Alternatives Considered**:
- External JSON/YAML file: Rejected (adds file I/O, version control complexity)
- Platform API lookup: Rejected (requires network, adds latency)
- AST pattern matching: Rejected (too brittle, hard to maintain)

---

### 4. Output Formatting

**Question**: How to provide color-coded CLI output and JSON output for CI/CD?

**Decision**: Use existing colorize/pastel pattern from SDK codebase

**Rationale**:
- SDK already uses colors in other CLI commands (exec, oauth2)
- Check for existing color library in dependencies
- JSON output via `--output` flag follows existing SDK convention
- TTY detection to auto-disable colors in CI environments

**Implementation Pattern**:
```ruby
def format_output(report)
  return report.to_json if @options[:output]

  report.findings.each do |finding|
    color = severity_color(finding.severity)
    puts colorize(format_finding(finding), color)
  end
end

def severity_color(severity)
  case severity
  when :error then :red
  when :warning then :yellow
  when :info then :blue
  end
end
```

**Alternatives Considered**:
- `tty-box` gem: Rejected (unnecessary visual complexity)
- ASCII tables: Rejected (harder to parse in CI logs)
- HTML output: Rejected (out of scope)

---

### 5. Performance Optimization

**Question**: How to ensure <10 second validation for 5000 line files?

**Decision**: Single-pass AST parsing + concurrent validator execution

**Rationale**:
- Parse once, share AST across all validators
- Validators can run concurrently (read-only operations)
- Use Ruby's `concurrent-ruby` gem (already in dependencies)
- Lazy loading: only parse if syntax validation passes

**Performance Budget**:
- Syntax check (Ripper): ~100ms for 5000 lines
- AST parsing: ~200ms for 5000 lines
- Each validator: <500ms (9 validators × 500ms = 4.5s)
- Report generation: ~50ms
- **Total**: ~5s (50% safety margin)

**Alternatives Considered**:
- Sequential execution: Rejected (would take ~5-6s without margin)
- Parallel processes: Rejected (overhead of IPC, complexity)
- Cached validation: Rejected (stateless by design)

---

### 6. Required Section Detection

**Question**: How to validate required top-level sections (title, connection, test)?

**Decision**: Hash key presence check after connector hash extraction

**Rationale**:
- Connector is Ruby hash; sections are top-level keys
- AST walk to find hash literal, convert to Ruby hash
- Check for required keys: `:title`, `:connection`, `:test`
- Line numbers extracted from AST for error reporting

**Implementation**:
```ruby
def validate_required_sections(connector_hash, ast)
  required = [:title, :connection, :test]
  missing = required - connector_hash.keys

  missing.each do |key|
    report_finding(
      rule_name: "required_section_#{key}",
      severity: :error,
      message: "Missing required section: #{key}",
      line_number: find_connector_hash_line(ast),
      suggested_fix: "Add #{key}: { ... } to connector definition"
    )
  end
end
```

**Alternatives Considered**:
- Regex matching: Rejected (unreliable, can't handle comments/strings)
- String search: Rejected (false positives)
- Full eval: Rejected (security risk)

---

### 7. Auth Type-Specific Validation

**Question**: How to validate auth blocks based on auth type (OAuth2, Basic, API Key)?

**Decision**: Auth type registry with required keys per type

**Rationale**:
- Different auth types have different required fields
- OAuth2 requires: `authorization_url`, `acquire`, `apply`, optionally `refresh`
- Basic auth requires: `apply`, optionally `detect_on`
- Extract `connection[:authorization][:type]`, lookup required keys

**Auth Registry**:
```ruby
AUTH_REQUIREMENTS = {
  oauth2: {
    required: [:authorization_url, :acquire, :apply],
    optional: [:refresh, :refresh_on, :detect_on]
  },
  basic_auth: {
    required: [:apply],
    optional: [:detect_on]
  },
  api_key: {
    required: [:apply],
    optional: [:detect_on]
  },
  custom_auth: {
    required: [:apply],
    optional: []
  }
}
```

**Alternatives Considered**:
- Hardcode each type: Rejected (violates DRY, hard to extend)
- Load from platform: Rejected (network dependency)

---

### 8. Reference Validation (object_definitions, pick_lists)

**Question**: How to detect dangling references to undefined object_definitions or pick_lists?

**Decision**: Two-pass approach: collect definitions, then validate references

**Rationale**:
1. First pass: Extract all defined `object_definitions` and `pick_lists` keys
2. Second pass: Find all references in actions/triggers (input_fields, output_fields, execute blocks)
3. Report references not in definition set

**Example**:
```ruby
def validate_references(connector_hash)
  # Pass 1: Collect definitions
  defined_objects = connector_hash.dig(:object_definitions)&.keys || []
  defined_picklists = connector_hash.dig(:pick_lists)&.keys || []

  # Pass 2: Find references in actions
  connector_hash.dig(:actions)&.each do |name, action|
    # Check input_fields references
    # Check output_fields references
    # Check execute block for .invoke('object_definition', ...)
  end
end
```

**Alternatives Considered**:
- Runtime execution: Rejected (too slow, requires test credentials)
- Static analysis on string literals: Rejected (misses dynamic references)

---

### 9. Block Signature Validation

**Question**: How to validate lambda signatures for execute, poll, webhook blocks?

**Decision**: AST inspection of lambda parameters

**Rationale**:
- Extract lambda nodes from AST
- Check parameter count and names
- `execute`: expects (connection, input, input_schema, output_schema, closure)
- `poll`: expects (connection, input, closure)
- `webhook_subscribe`: expects (webhook_url, connection, input, recipe_id)

**Implementation**:
```ruby
def validate_execute_signature(action_name, execute_lambda_ast)
  params = extract_lambda_params(execute_lambda_ast)
  expected = ['connection', 'input', 'input_schema', 'output_schema', 'closure']

  if params.length < 2
    report_error("Action #{action_name} execute must accept at least (connection, input)")
  end
end
```

**Alternatives Considered**:
- Parse source string: Rejected (unreliable, doesn't handle comments)
- Execute and introspect: Rejected (security, requires valid connection)

---

### 10. Test Infrastructure

**Question**: What test fixtures are needed for comprehensive validation testing?

**Decision**: Fixture library covering each validation rule

**Required Fixtures**:
1. `valid_connector.rb` - Passes all validations
2. `invalid_syntax_connector.rb` - Ruby syntax errors (FR-004)
3. `missing_sections_connector.rb` - Missing title/connection/test (FR-002)
4. `invalid_auth_connector.rb` - OAuth2 missing acquire (FR-003)
5. `dangling_refs_connector.rb` - Undefined object_definitions (FR-005)
6. `invalid_signatures_connector.rb` - Wrong lambda params (FR-007)
7. `deprecated_dsl_connector.rb` - Uses deprecated methods (FR-010)
8. `invalid_field_types_connector.rb` - Wrong field types (FR-011)
9. `hardcoded_credentials_connector.rb` - Security anti-pattern (FR-012)

**Test Strategy**:
- Each validator has isolated unit tests with minimal fixtures
- Integration test uses full fixtures to test end-to-end CLI
- Use VCR pattern for consistency (even though no HTTP calls)

---

## Summary of Technical Decisions

| Area | Technology/Approach | Rationale |
|------|-------------------|-----------|
| AST Parsing | Ripper (stdlib) | No external deps, sufficient features |
| Architecture | Strategy pattern with isolated validators | Single responsibility, testable, extensible |
| Deprecation Registry | Ruby hash constant | Simple, versionable, centralized |
| Output Formatting | Existing SDK color library + JSON | Consistent with SDK, supports CI/CD |
| Performance | Single-pass parse + concurrent validators | Meets <10s requirement with safety margin |
| Section Detection | Hash key presence after extraction | Direct, reliable |
| Auth Validation | Type registry with required keys | Extensible, maintainable |
| Reference Validation | Two-pass collect-then-validate | Complete coverage, handles forward refs |
| Signature Validation | AST parameter inspection | Accurate, doesn't require execution |
| Test Strategy | Fixture library + unit + integration tests | Comprehensive, maintainable |

---

**Research Complete**: All technical unknowns resolved. Ready for Phase 1 design.