# CLI Interface Contract: workato validate

**Feature**: Workato Validate Command
**Date**: 2025-01-29
**Type**: Command-Line Interface Specification

## Command Signature

```bash
workato validate [OPTIONS]
```

## Options

| Flag | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `--connector=PATH` | String | No | `connector.rb` | Path to connector file to validate (absolute or relative) |
| `--output=PATH` | String | No | (stdout) | Write JSON report to file instead of human-readable output |
| `--verbose`, `-v` | Boolean | No | `false` | Show all checks performed, not just failures |
| `--help`, `-h` | Boolean | No | `false` | Display help message with examples |

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `0` | Success | Validation passed with no errors or warnings |
| `1` | Failure | Validation failed with one or more errors |
| `2` | Warnings | Validation passed but warnings were found |

## Examples

### Example 1: Validate default connector.rb

```bash
workato validate
```

**Expected Output** (valid connector):
```
Validating connector.rb...

✓ Connector validation passed

Duration: 0.123s
```

**Expected Exit Code**: `0`

---

### Example 2: Validate with errors

```bash
workato validate --connector=custom_connector.rb
```

**Expected Output** (invalid connector):
```
Validating custom_connector.rb...

❌ ERROR (line 1): Missing required section: test
   → Add test: lambda { |connection| ... } to connector definition

❌ ERROR (line 23): OAuth2 authorization missing required key: acquire
   → Add acquire: lambda { |connection, auth_code, redirect_uri| ... }

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 2 errors
Duration: 0.234s
```

**Expected Exit Code**: `1`

---

### Example 3: Validate with warnings

```bash
workato validate
```

**Expected Output** (deprecated patterns):
```
Validating connector.rb...

⚠️  WARNING (line 45): Use of deprecated method after_error_response
   → Replace with error_handler block

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation passed with warnings: 1 warning
Duration: 0.156s
```

**Expected Exit Code**: `2`

---

### Example 4: JSON output for CI/CD

```bash
workato validate --output=validation-report.json
```

**Expected Output** (stdout):
```
Validation report written to validation-report.json
```

**Expected File Content** (validation-report.json):
```json
{
  "connector_path": "/Users/dave/project/connector.rb",
  "validated_at": "2025-01-29T12:34:56Z",
  "status": "fail",
  "duration_ms": 234,
  "summary": {
    "error_count": 2,
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
    },
    {
      "rule_name": "invalid_oauth2_config",
      "severity": "error",
      "message": "OAuth2 authorization missing required key: acquire",
      "line_number": 23,
      "column_number": null,
      "suggested_fix": "Add acquire: lambda { |connection, auth_code, redirect_uri| ... }",
      "context": {
        "auth_type": "oauth2",
        "missing_keys": ["acquire"],
        "present_keys": ["authorization_url", "apply"]
      }
    }
  ]
}
```

**Expected Exit Code**: `1`

---

### Example 5: Verbose mode

```bash
workato validate --verbose
```

**Expected Output** (valid connector):
```
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
```

**Expected Exit Code**: `0`

---

### Example 6: File not found

```bash
workato validate --connector=nonexistent.rb
```

**Expected Output**:
```
ERROR: Connector file not found at 'nonexistent.rb'

Suggestion: Check the file path, or run 'workato new' to create a new connector.
```

**Expected Exit Code**: `1`

---

### Example 7: Invalid syntax

```bash
workato validate --connector=broken.rb
```

**Expected Output**:
```
Validating broken.rb...

❌ ERROR (line 12): Ruby syntax error: unexpected end-of-input, expecting '}'
   → Fix the syntax error at the indicated line

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Validation failed: 1 error
Duration: 0.045s
```

**Expected Exit Code**: `1`

---

## Help Output

```bash
workato help validate
```

**Expected Output**:
```
Usage:
  workato validate [OPTIONS]

Options:
  -c, [--connector=CONNECTOR]  # Path to connector source code
                               # Default: connector.rb
  -o, [--output=OUTPUT]        # Write JSON validation report to file
  -v, [--verbose]              # Show all checks performed, not just failures
      [--help]                 # Display this help message

Description:
  Validates connector code for structural errors, missing required sections,
  invalid syntax, and DSL convention violations before deployment.

  The validate command checks your connector.rb file against 25+ validation
  rules including:
  - Required sections (title, connection, test)
  - Connection authorization configuration
  - Ruby syntax validity
  - Object definition and pick list references
  - Lambda block signatures for actions/triggers
  - Field type definitions
  - Deprecated DSL patterns
  - Security anti-patterns

  Exit codes:
    0 - Validation passed (no errors or warnings)
    1 - Validation failed (errors found)
    2 - Validation passed with warnings

Examples:
  # Validate default connector.rb
  workato validate

  # Validate specific connector file
  workato validate --connector=custom_connector.rb

  # Output JSON report for CI/CD
  workato validate --output=report.json

  # Show all checks, not just failures
  workato validate --verbose
```

---

## Error Handling

### Missing file

**Input**: `workato validate --connector=missing.rb`

**Behavior**:
1. Check if file exists
2. If not: print error message with suggestion
3. Exit with code 1

**Error Format**:
```
ERROR: Connector file not found at 'missing.rb'

Suggestion: Check the file path, or run 'workato new' to create a new connector.
```

---

### Permission denied

**Input**: `workato validate --connector=/root/protected.rb`

**Behavior**:
1. Attempt to read file
2. If permission error: print error message
3. Exit with code 1

**Error Format**:
```
ERROR: Permission denied reading '/root/protected.rb'

Suggestion: Check file permissions and ensure you have read access.
```

---

### Output file write error

**Input**: `workato validate --output=/readonly/report.json`

**Behavior**:
1. Run validation
2. Attempt to write output file
3. If write error: print error message
4. Exit with code 1

**Error Format**:
```
ERROR: Cannot write to '/readonly/report.json': Permission denied

Suggestion: Check the output directory exists and is writable.
```

---

## Performance Contract

| Scenario | File Size | Max Duration | Notes |
|----------|-----------|--------------|-------|
| Small connector | <500 lines | <1s | Typical simple connector |
| Medium connector | 500-2000 lines | <3s | Average connector |
| Large connector | 2000-5000 lines | <10s | FR-019 requirement |
| Syntax error | Any size | <500ms | Early exit after syntax check |
| Invalid structure | Any size | <1s | Early exit after structure check |

---

## Integration with Existing SDK

### Consistency with Other Commands

The `validate` command follows existing SDK CLI patterns:

| Pattern | Example from `exec` | Example from `validate` |
|---------|-------------------|------------------------|
| Connector flag | `--connector=PATH` | `--connector=PATH` |
| Default behavior | Assumes `connector.rb` | Assumes `connector.rb` |
| Output flag | `--output=FILE` | `--output=FILE` |
| Verbose flag | `--verbose` | `--verbose` |
| Help text | `workato help exec` | `workato help validate` |
| Error format | Descriptive + actionable | Descriptive + actionable |

### Differences from Other Commands

| Aspect | Other Commands | `validate` |
|--------|---------------|------------|
| Settings | Requires settings.yaml | Not required (no auth) |
| Connection | Tests actual connection | Static analysis only |
| Execution | Runs connector code | Parses but doesn't execute |
| Dependencies | Needs valid credentials | No external dependencies |

---

## Contract Test Cases

These test cases will be implemented in `spec/workato/cli/validate_command_spec.rb`:

1. **Valid connector → exit 0, success message**
2. **Missing required section → exit 1, error with line number**
3. **Invalid OAuth2 config → exit 1, error with suggested fix**
4. **Deprecated DSL → exit 2, warning with replacement**
5. **File not found → exit 1, actionable error**
6. **Syntax error → exit 1, error with line number**
7. **JSON output → exit based on status, valid JSON written**
8. **Verbose mode → exit 0, shows all checks**
9. **Custom connector path → validates specified file**
10. **Large file (5000 lines) → completes within 10 seconds**

---

**CLI Contract Complete**: Ready for test-driven implementation.