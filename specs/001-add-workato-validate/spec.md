# Feature Specification: Workato Validate Command

**Feature Branch**: `001-add-workato-validate`
**Created**: 2025-01-29
**Status**: Draft
**Input**: User description: "add workato validate command for linting and validating connector structure"

## Execution Flow (main)
```
1. Parse user description from Input
   → Feature: CLI command for connector validation
2. Extract key concepts from description
   → Actors: Connector developers
   → Actions: Validate, lint, check structure
   → Data: Connector code files
   → Constraints: Must follow SDK conventions
3. For each unclear aspect:
   → Validation rules not specified in detail
4. Fill User Scenarios & Testing section
   → Clear: Developer runs command, gets validation report
5. Generate Functional Requirements
   → Each requirement testable via CLI execution
6. Identify Key Entities
   → ValidationReport, ValidationRule, ConnectorStructure
7. Run Review Checklist
   → No NEEDS CLARIFICATION remain
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing

### Primary User Story
As a connector developer, I want to validate my connector code before pushing to Workato so that I can catch structural errors, missing required sections, and convention violations early in development rather than discovering issues after deployment.

### Acceptance Scenarios
1. **Given** a valid connector.rb file in the current directory, **When** I run `workato validate`, **Then** the command exits successfully with a message "✓ Connector validation passed" and returns exit code 0
2. **Given** a connector.rb with missing required sections (e.g., no `test:` block), **When** I run `workato validate`, **Then** the command reports specific missing sections and returns exit code 1
3. **Given** a connector.rb with invalid syntax, **When** I run `workato validate`, **Then** the command shows syntax errors with line numbers and exits with code 1
4. **Given** a connector.rb with deprecated DSL patterns, **When** I run `workato validate`, **Then** the command warns about deprecated usage and suggests modern alternatives
5. **Given** I want to validate a specific file, **When** I run `workato validate --connector=custom_connector.rb`, **Then** the command validates that specific file instead of the default connector.rb
6. **Given** I want detailed validation output, **When** I run `workato validate --verbose`, **Then** the command shows all checks performed, not just failures
7. **Given** I want machine-readable output for CI/CD, **When** I run `workato validate --output=report.json`, **Then** the command writes structured validation results to the JSON file

### Edge Cases
- What happens when connector.rb doesn't exist? System MUST provide clear error message with suggestion to run `workato new`
- How does system handle connectors with multi-auth configurations? Validation MUST check all auth type definitions
- What happens when connection settings reference undefined object_definitions? System MUST report dangling references
- How does system handle very large connector files (>5000 lines)? Validation MUST complete within 10 seconds
- What happens when running validate on a directory without write permissions for report output? System MUST gracefully handle permission errors

## Requirements

### Functional Requirements
- **FR-001**: System MUST validate connector.rb file exists and is readable before performing any checks
- **FR-002**: System MUST check for required top-level connector sections: `title`, `connection`, `test`
- **FR-003**: System MUST validate connection authorization block contains required keys based on auth type (e.g., OAuth2 requires `authorization_url`, `acquire`, `apply`)
- **FR-004**: System MUST detect invalid Ruby syntax and report line numbers with error messages
- **FR-005**: System MUST validate that all `object_definitions` referenced in actions/triggers are defined
- **FR-006**: System MUST check that all `pick_lists` referenced in input/output fields are defined
- **FR-007**: System MUST validate that action `execute` blocks have correct parameter signatures (connection, input, input_schema, output_schema, closure)
- **FR-008**: System MUST validate that trigger `poll` blocks have correct parameter signatures (connection, input, closure)
- **FR-009**: System MUST validate that webhook trigger definitions include `webhook_subscribe`, `webhook_notification`, and optionally `webhook_unsubscribe`
- **FR-010**: System MUST detect deprecated DSL methods and suggest modern equivalents
- **FR-011**: System MUST validate that field definitions use correct type values (string, integer, number, boolean, date, datetime, timestamp, object, array)
- **FR-012**: System MUST check for common anti-patterns (e.g., hardcoded credentials in connector code)
- **FR-013**: System MUST validate that `methods` blocks only contain lambda definitions
- **FR-014**: System MUST check that action/trigger names are valid Ruby symbols (no spaces, special characters)
- **FR-015**: Users MUST be able to specify which connector file to validate via `--connector` flag
- **FR-016**: Users MUST be able to output validation results to JSON format via `--output` flag for CI/CD integration
- **FR-017**: System MUST provide human-readable output by default with color-coded severity (errors in red, warnings in yellow, info in blue)
- **FR-018**: System MUST return exit code 0 for passed validation, exit code 1 for failed validation (errors present), exit code 2 for warnings only
- **FR-019**: System MUST complete validation within 10 seconds for connectors up to 5000 lines
- **FR-020**: System MUST support `--verbose` flag to show all checks performed, not just failures
- **FR-021**: System MUST validate that stream definitions have correct signatures and return correct tuple format
- **FR-022**: System MUST check that CSV, JWT, and encryption methods are used correctly with proper parameters
- **FR-023**: System MUST validate that `summarize_input` and `summarize_output` references point to valid field paths
- **FR-024**: System MUST provide suggestions for fixing detected issues when possible
- **FR-025**: System MUST validate that parallel request configurations specify valid thread counts and rate limits

### Key Entities

- **ValidationReport**: Represents the complete validation outcome containing all findings (errors, warnings, info), validation timestamp, connector file path, and overall pass/fail status

- **ValidationRule**: Represents a single validation check with rule name, severity level (error/warning/info), description of what is checked, and validation logic criteria

- **ConnectorStructure**: Represents the parsed connector code structure including defined sections (connection, actions, triggers, methods, object_definitions, pick_lists), authentication type, and referenced dependencies

- **ValidationFinding**: Represents a specific issue discovered during validation containing rule name, severity, message, line number (if applicable), and suggested fix

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable (exit codes, validation rules checked)
- [x] Scope is clearly bounded (connector validation only, no deployment or execution)
- [x] Dependencies and assumptions identified (requires connector.rb file, Ruby syntax parser)

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (none remaining)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---