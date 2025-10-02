# Data Model: Workato Validate Command

**Feature**: Workato Validate Command
**Date**: 2025-01-29
**Status**: Complete

## Entities

### 1. ValidationReport

**Purpose**: Represents the complete validation outcome for a connector file

**Attributes**:
- `connector_path` (String): Absolute path to validated connector file
- `validated_at` (Time): Timestamp when validation was performed
- `findings` (Array<ValidationFinding>): All findings discovered during validation
- `status` (Symbol): Overall status - `:pass`, `:fail`, `:warnings_only`
- `duration_ms` (Integer): Time taken to complete validation in milliseconds

**Derived Attributes**:
- `errors` -> findings.select { |f| f.severity == :error }
- `warnings` -> findings.select { |f| f.severity == :warning }
- `infos` -> findings.select { |f| f.severity == :info }
- `error_count` -> errors.length
- `warning_count` -> warnings.length
- `info_count` -> infos.length

**Behaviors**:
- `pass?` -> status == :pass (no errors)
- `fail?` -> status == :fail (has errors)
- `exit_code` -> returns 0 for pass, 1 for fail, 2 for warnings_only
- `to_json` -> structured JSON representation for CI/CD tools
- `to_human` -> color-coded human-readable output

**Validation Rules**:
- connector_path must be non-empty string
- findings must be array (can be empty)
- status must be one of: :pass, :fail, :warnings_only
- duration_ms must be non-negative integer

**State Transitions**:
```
Initial -> Validating
Validating -> Complete (findings collected)
Complete -> (terminal state)
```

---

### 2. ValidationFinding

**Purpose**: Represents a specific issue discovered during validation

**Attributes**:
- `rule_name` (String): Identifier for the validation rule that generated this finding (e.g., "required_section_test", "invalid_oauth2_config")
- `severity` (Symbol): Impact level - `:error`, `:warning`, or `:info`
- `message` (String): Human-readable description of the issue
- `line_number` (Integer, optional): Line number where issue occurs (nil if file-level)
- `column_number` (Integer, optional): Column number for precise location
- `suggested_fix` (String, optional): Actionable recommendation to resolve the issue
- `context` (Hash, optional): Additional contextual information (e.g., { expected: [...], actual: [...] })

**Behaviors**:
- `error?` -> severity == :error
- `warning?` -> severity == :warning
- `info?` -> severity == :info
- `location_string` -> formats "line X" or "line X:Y" or "file-level"
- `to_s` -> formatted string for display

**Validation Rules**:
- rule_name must be non-empty string
- severity must be one of: :error, :warning, :info
- message must be non-empty string
- line_number must be positive integer if present
- column_number must be positive integer if present

**Examples**:
```ruby
ValidationFinding.new(
  rule_name: 'required_section_test',
  severity: :error,
  message: 'Missing required section: test',
  line_number: 1,
  suggested_fix: 'Add test: lambda { |connection| ... } to connector definition'
)

ValidationFinding.new(
  rule_name: 'deprecated_dsl_method',
  severity: :warning,
  message: 'Use of deprecated method after_error_response',
  line_number: 45,
  suggested_fix: 'Replace with error_handler block'
)
```

---

### 3. ValidationRule

**Purpose**: Represents a single validation check with metadata

**Attributes**:
- `name` (String): Unique identifier (e.g., "required_section_title")
- `description` (String): Human-readable description of what is checked
- `severity` (Symbol): Default severity level if rule is violated
- `functional_requirement` (String, optional): Reference to spec FR-XXX

**Behaviors**:
- `check(connector_structure)` -> returns Array<ValidationFinding> (abstract method)

**Validation Rules**:
- name must be unique across all rules
- description must be non-empty
- severity must be one of: :error, :warning, :info

**Examples**:
```ruby
ValidationRule.new(
  name: 'required_section_connection',
  description: 'Validates presence of required connection section',
  severity: :error,
  functional_requirement: 'FR-002'
)
```

---

### 4. ConnectorStructure

**Purpose**: Represents the parsed connector code structure

**Attributes**:
- `source_code` (String): Raw connector.rb file contents
- `ast` (Ripper::SexpBuilder result, optional): Abstract syntax tree (nil if syntax invalid)
- `connector_hash` (Hash, optional): Extracted connector definition hash (nil if structure invalid)
- `syntax_valid` (Boolean): Whether Ruby syntax is valid
- `parse_errors` (Array<String>): Syntax error messages if syntax_valid is false

**Derived Attributes** (extracted from connector_hash):
- `title` -> connector_hash[:title]
- `connection` -> connector_hash[:connection]
- `test` -> connector_hash[:test]
- `actions` -> connector_hash[:actions] || {}
- `triggers` -> connector_hash[:triggers] || {}
- `methods` -> connector_hash[:methods] || {}
- `object_definitions` -> connector_hash[:object_definitions] || {}
- `pick_lists` -> connector_hash[:pick_lists] || {}
- `webhook_keys` -> connector_hash[:webhook_keys] || []

**Authentication Attributes**:
- `auth_type` -> connection.dig(:authorization, :type)
- `auth_fields` -> connection.dig(:authorization).keys (array of present auth keys)

**Reference Collections**:
- `defined_object_definitions` -> object_definitions.keys
- `defined_pick_lists` -> pick_lists.keys
- `defined_methods` -> methods.keys

**Behaviors**:
- `parse!` -> parses source_code into AST and connector_hash
- `section_line_number(section_name)` -> finds line number of given section
- `action_execute_params(action_name)` -> extracts execute lambda parameters
- `trigger_poll_params(trigger_name)` -> extracts poll lambda parameters

**Validation Rules**:
- source_code must be non-empty string
- if syntax_valid is true, ast must be present
- if ast is present, connector_hash extraction should be attempted

**State Transitions**:
```
Unparsed -> Parsing
Parsing -> SyntaxError (syntax_valid = false, parse_errors populated)
Parsing -> Parsed (syntax_valid = true, ast + connector_hash populated)
```

---

## Relationships

```
ValidationReport "1" --* "0..*" ValidationFinding
  (report contains zero or more findings)

ValidationRule "1" --> "0..*" ValidationFinding
  (rule generates zero or more findings when violated)

ValidateCommand "1" --> "1" ConnectorStructure
  (command validates one connector structure)

ValidateCommand "1" --> "many" ValidationRule
  (command applies many validation rules)

ValidateCommand "1" --> "1" ValidationReport
  (command produces one validation report)

BaseValidator "1" --> "1" ConnectorStructure
  (validator inspects connector structure)

BaseValidator "1" --> "0..*" ValidationFinding
  (validator produces zero or more findings)
```

---

## Validation Workflow

1. **Load Connector File**
   - Read connector.rb file from disk
   - Create ConnectorStructure with source_code

2. **Parse Structure**
   - Call `ConnectorStructure#parse!`
   - If syntax invalid: create ValidationFinding for syntax errors, short-circuit
   - If syntax valid: extract connector_hash from AST

3. **Execute Validators**
   - Instantiate all validator classes (9 validators)
   - Run validators concurrently (using concurrent-ruby)
   - Each validator produces Array<ValidationFinding>

4. **Aggregate Findings**
   - Collect findings from all validators
   - Sort by: severity (errors first), then line_number

5. **Generate Report**
   - Create ValidationReport with all findings
   - Calculate status based on presence of errors
   - Record duration_ms

6. **Output Report**
   - If --output flag: write report.to_json to file
   - Otherwise: print report.to_human with colors
   - Exit with report.exit_code

---

## Validation Rule Mapping

Each validator is responsible for specific functional requirements:

| Validator Class | Functional Requirements | Entity Dependencies |
|----------------|------------------------|---------------------|
| SyntaxValidator | FR-004 | ConnectorStructure (source_code) |
| StructureValidator | FR-001, FR-002 | ConnectorStructure (connector_hash) |
| ConnectionValidator | FR-003 | ConnectorStructure (connection, auth_type) |
| ReferenceValidator | FR-005, FR-006 | ConnectorStructure (actions, triggers, object_definitions, pick_lists) |
| SignatureValidator | FR-007, FR-008, FR-009, FR-021 | ConnectorStructure (actions, triggers, AST) |
| FieldValidator | FR-011, FR-023 | ConnectorStructure (actions, triggers, object_definitions) |
| DeprecationValidator | FR-010 | ConnectorStructure (AST, source_code) |
| AntiPatternValidator | FR-012, FR-013, FR-014, FR-022, FR-024, FR-025 | ConnectorStructure (methods, actions, triggers, AST) |

---

## JSON Output Schema

For CI/CD integration (FR-016), the JSON output format:

```json
{
  "connector_path": "/path/to/connector.rb",
  "validated_at": "2025-01-29T12:34:56Z",
  "status": "fail",
  "duration_ms": 234,
  "summary": {
    "error_count": 2,
    "warning_count": 1,
    "info_count": 0
  },
  "findings": [
    {
      "rule_name": "required_section_test",
      "severity": "error",
      "message": "Missing required section: test",
      "line_number": 1,
      "column_number": null,
      "suggested_fix": "Add test: lambda { |connection| ... } to connector definition",
      "context": {}
    },
    {
      "rule_name": "deprecated_dsl_method",
      "severity": "warning",
      "message": "Use of deprecated method after_error_response",
      "line_number": 45,
      "column_number": 12,
      "suggested_fix": "Replace with error_handler block",
      "context": {
        "deprecated_method": "after_error_response",
        "replacement": "error_handler"
      }
    }
  ]
}
```

---

## Human-Readable Output Format

Default console output (FR-017):

```
Validating connector.rb...

❌ ERROR (line 1): Missing required section: test
   → Add test: lambda { |connection| ... } to connector definition

⚠️  WARNING (line 45): Use of deprecated method after_error_response
   → Replace with error_handler block

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 2 errors, 1 warning
Duration: 0.234s
```

---

**Data Model Complete**: All entities, relationships, and validation workflows defined. Ready for contract generation.