# Quickstart: Workato Validate Command

**Feature**: Workato Validate Command
**Purpose**: Verify the implementation by executing user acceptance scenarios
**Date**: 2025-01-29

## Prerequisites

- Workato Connector SDK installed
- Ruby >= 2.7.6
- Test connector files in `spec/fixtures/validation/`

---

## Test Scenario 1: Valid Connector (Acceptance Scenario 1)

**Given** a valid connector.rb file in the current directory

**When** I run `workato validate`

**Then** the command exits successfully with a message "✓ Connector validation passed" and returns exit code 0

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/valid_connector_test
cp valid_connector.rb connector.rb

# Execute
workato validate

# Expected Output
Validating connector.rb...

✓ Connector validation passed

Duration: 0.123s

# Verify exit code
echo $?
# Expected: 0
```

**Success Criteria**:
- [ ] Exit code is 0
- [ ] Output contains "✓ Connector validation passed"
- [ ] No errors or warnings displayed
- [ ] Completes in <2 seconds

---

## Test Scenario 2: Missing Required Section (Acceptance Scenario 2)

**Given** a connector.rb with missing required sections (e.g., no `test:` block)

**When** I run `workato validate`

**Then** the command reports specific missing sections and returns exit code 1

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/missing_sections_test
cp missing_test_section_connector.rb connector.rb

# Execute
workato validate

# Expected Output
Validating connector.rb...

❌ ERROR (line 1): Missing required section: test
   → Add test: lambda { |connection| ... } to connector definition

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 1 error
Duration: 0.089s

# Verify exit code
echo $?
# Expected: 1
```

**Success Criteria**:
- [ ] Exit code is 1
- [ ] Output contains "Missing required section: test"
- [ ] Suggested fix is provided
- [ ] Line number is shown (if applicable)

---

## Test Scenario 3: Invalid Syntax (Acceptance Scenario 3)

**Given** a connector.rb with invalid syntax

**When** I run `workato validate`

**Then** the command shows syntax errors with line numbers and exits with code 1

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/invalid_syntax_test
cp invalid_syntax_connector.rb connector.rb

# Execute
workato validate

# Expected Output
Validating connector.rb...

❌ ERROR (line 12): Ruby syntax error: unexpected end-of-input, expecting '}'
   → Fix the syntax error at the indicated line

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 1 error
Duration: 0.045s

# Verify exit code
echo $?
# Expected: 1
```

**Success Criteria**:
- [ ] Exit code is 1
- [ ] Output contains "Ruby syntax error"
- [ ] Line number 12 is shown
- [ ] Validation exits early (fast failure)

---

## Test Scenario 4: Deprecated DSL Patterns (Acceptance Scenario 4)

**Given** a connector.rb with deprecated DSL patterns

**When** I run `workato validate`

**Then** the command warns about deprecated usage and suggests modern alternatives

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/deprecated_patterns_test
cp deprecated_dsl_connector.rb connector.rb

# Execute
workato validate

# Expected Output
Validating connector.rb...

⚠️  WARNING (line 45): Use of deprecated method after_error_response
   → Replace with error_handler block

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation passed with warnings: 1 warning
Duration: 0.156s

# Verify exit code
echo $?
# Expected: 2
```

**Success Criteria**:
- [ ] Exit code is 2 (warnings only)
- [ ] Output contains "⚠️  WARNING"
- [ ] Deprecated method name is shown
- [ ] Modern alternative is suggested
- [ ] Line number is accurate

---

## Test Scenario 5: Custom File Path (Acceptance Scenario 5)

**Given** I want to validate a specific file

**When** I run `workato validate --connector=custom_connector.rb`

**Then** the command validates that specific file instead of the default connector.rb

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/custom_path_test
# Note: NO connector.rb exists, only custom_connector.rb
cp valid_connector.rb custom_connector.rb

# Execute with custom path
workato validate --connector=custom_connector.rb

# Expected Output
Validating custom_connector.rb...

✓ Connector validation passed

Duration: 0.134s

# Verify exit code
echo $?
# Expected: 0
```

**Success Criteria**:
- [ ] Validates custom_connector.rb, not connector.rb
- [ ] Exit code is 0
- [ ] Output shows correct filename
- [ ] Does not error on missing connector.rb

---

## Test Scenario 6: Verbose Output (Acceptance Scenario 6)

**Given** I want detailed validation output

**When** I run `workato validate --verbose`

**Then** the command shows all checks performed, not just failures

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/valid_connector_test
cp valid_connector.rb connector.rb

# Execute with verbose flag
workato validate --verbose

# Expected Output
Validating connector.rb...

✓ Syntax validation passed
✓ Required sections present: title, connection, test
✓ Connection authorization valid (type: oauth2)
✓ All object_definitions references resolved
✓ All pick_lists references resolved
✓ Action execute signatures valid (3 actions checked)
✓ Trigger poll signatures valid (2 triggers checked)
✓ Field types valid
✓ No deprecated DSL patterns found
✓ No anti-patterns detected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Connector validation passed

Duration: 0.189s

# Verify exit code
echo $?
# Expected: 0
```

**Success Criteria**:
- [ ] Shows all validation rules checked (not just failures)
- [ ] Each check has ✓ indicator
- [ ] Counts shown (e.g., "3 actions checked")
- [ ] Exit code is 0
- [ ] Duration slightly longer than non-verbose

---

## Test Scenario 7: JSON Output for CI/CD (Acceptance Scenario 7)

**Given** I want machine-readable output for CI/CD

**When** I run `workato validate --output=report.json`

**Then** the command writes structured validation results to the JSON file

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/missing_sections_test
cp missing_test_section_connector.rb connector.rb
rm -f report.json

# Execute with JSON output
workato validate --output=report.json

# Expected Output (stdout)
Validation report written to report.json

# Verify exit code
echo $?
# Expected: 1

# Verify JSON structure
cat report.json | jq .
# Expected: Valid JSON with findings array
```

**Expected JSON Structure**:
```json
{
  "connector_path": "/path/to/connector.rb",
  "validated_at": "2025-01-29T12:34:56Z",
  "status": "fail",
  "duration_ms": 89,
  "summary": {
    "error_count": 1,
    "warning_count": 0,
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
    }
  ]
}
```

**Success Criteria**:
- [ ] report.json file is created
- [ ] JSON is valid and parseable
- [ ] Contains all required fields (connector_path, validated_at, status, findings)
- [ ] Exit code matches validation result (1 for failure)
- [ ] No human-readable output to stdout (except confirmation message)

---

## Edge Case 1: Non-Existent File

**Given** connector.rb doesn't exist

**When** I run `workato validate`

**Then** System MUST provide clear error message with suggestion to run `workato new`

### Execution Steps

```bash
# Setup
cd /tmp/empty_directory
rm -f connector.rb

# Execute
workato validate

# Expected Output
ERROR: Connector file not found at 'connector.rb'

Suggestion: Check the file path, or run 'workato new' to create a new connector.

# Verify exit code
echo $?
# Expected: 1
```

**Success Criteria**:
- [ ] Exit code is 1
- [ ] Error message is clear and actionable
- [ ] Suggests running `workato new`
- [ ] No stack trace or confusing technical errors

---

## Edge Case 2: Large Connector File

**Given** a very large connector file (>5000 lines)

**When** I run `workato validate`

**Then** System MUST complete within 10 seconds (FR-019)

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/large_connector_test
# large_connector.rb is a 5000-line connector

# Execute with timing
time workato validate --connector=large_connector.rb

# Expected Output (timing shown)
Validating large_connector.rb...

✓ Connector validation passed

Duration: 8.456s

real    0m8.456s
user    0m7.890s
sys     0m0.234s
```

**Success Criteria**:
- [ ] Completes in <10 seconds (FR-019)
- [ ] No timeout or hanging
- [ ] Memory usage stays <512MB
- [ ] All validations still run

---

## Edge Case 3: Multi-Auth Configurations

**Given** a connector with multi-auth configurations (multiple auth types)

**When** I run `workato validate`

**Then** Validation MUST check all auth type definitions

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/multi_auth_test
cp multi_auth_connector.rb connector.rb

# Execute
workato validate

# Expected behavior:
# - Checks auth type 1 (oauth2)
# - Checks auth type 2 (api_key)
# - Reports issues in any auth type
```

**Success Criteria**:
- [ ] All auth types are validated
- [ ] Errors reported for each invalid auth type
- [ ] No false positives due to multiple auth configs

---

## Edge Case 4: Dangling Object Definition References

**Given** connection settings reference undefined object_definitions

**When** I run `workato validate`

**Then** System MUST report dangling references

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/dangling_refs_test
cp dangling_refs_connector.rb connector.rb

# Execute
workato validate

# Expected Output
Validating connector.rb...

❌ ERROR (line 67): Action 'search_customers' references undefined object_definition: 'customer'
   → Define object_definitions: { customer: { ... } } in connector

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 1 error
Duration: 0.145s
```

**Success Criteria**:
- [ ] Dangling reference is detected
- [ ] Referenced name is shown ('customer')
- [ ] Location in code is shown (line 67)
- [ ] Suggested fix is provided

---

## Edge Case 5: Permission Error on Output File

**Given** running validate on a directory without write permissions for report output

**When** I run `workato validate --output=/readonly/report.json`

**Then** System MUST gracefully handle permission errors

### Execution Steps

```bash
# Setup
cd spec/fixtures/validation/valid_connector_test
mkdir /tmp/readonly_test
chmod 444 /tmp/readonly_test  # Read-only

# Execute
workato validate --output=/tmp/readonly_test/report.json

# Expected Output
ERROR: Cannot write to '/tmp/readonly_test/report.json': Permission denied

Suggestion: Check the output directory exists and is writable.

# Verify exit code
echo $?
# Expected: 1
```

**Success Criteria**:
- [ ] Permission error is caught and handled
- [ ] User-friendly error message (not stack trace)
- [ ] Exit code is 1
- [ ] Validation still runs (error occurs at write time)

---

## Integration Test: CI/CD Pipeline

**Scenario**: Automated validation in GitHub Actions

### GitHub Actions Workflow

```yaml
name: Validate Connector

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
          bundler-cache: true

      - name: Install SDK
        run: gem install workato-connector-sdk

      - name: Validate connector
        run: workato validate --output=validation-report.json

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: validation-report.json

      - name: Fail on validation errors
        run: |
          STATUS=$(jq -r '.status' validation-report.json)
          if [ "$STATUS" = "fail" ]; then
            echo "Connector validation failed"
            jq -r '.findings[] | "[\(.severity)] \(.message)"' validation-report.json
            exit 1
          fi
```

**Success Criteria**:
- [ ] CI job runs `workato validate`
- [ ] JSON report is generated
- [ ] Job fails if validation fails (exit code 1)
- [ ] Report artifact is uploaded for review
- [ ] Findings are extracted and displayed in CI logs

---

## Quickstart Checklist

Run all scenarios in order to verify complete implementation:

- [ ] Test Scenario 1: Valid connector → exit 0
- [ ] Test Scenario 2: Missing required section → exit 1
- [ ] Test Scenario 3: Invalid syntax → exit 1
- [ ] Test Scenario 4: Deprecated DSL → exit 2
- [ ] Test Scenario 5: Custom file path → validates specified file
- [ ] Test Scenario 6: Verbose output → shows all checks
- [ ] Test Scenario 7: JSON output → valid JSON file
- [ ] Edge Case 1: Non-existent file → clear error
- [ ] Edge Case 2: Large file → completes <10s
- [ ] Edge Case 3: Multi-auth → all auth types checked
- [ ] Edge Case 4: Dangling refs → errors reported
- [ ] Edge Case 5: Permission error → graceful handling
- [ ] Integration Test: CI/CD → works in GitHub Actions

---

## Troubleshooting

### Issue: "command not found: workato"

**Solution**: Ensure SDK is installed:
```bash
gem install workato-connector-sdk
# or
bundle install
```

### Issue: Validation unexpectedly slow

**Check**:
1. File size: `wc -l connector.rb`
2. Profile execution: `time workato validate --verbose`
3. Check for infinite loops or recursion in validators

### Issue: Exit code always 0

**Check**:
1. Ensure ValidationReport.exit_code is correctly implemented
2. Verify findings are being collected
3. Check status calculation logic

### Issue: Colors not showing in CI

**Expected**: Colors auto-disable when not running in TTY
**Verify**: `tty` command returns "not a tty" in CI environment

---

**Quickstart Complete**: All acceptance scenarios and edge cases documented with executable steps.