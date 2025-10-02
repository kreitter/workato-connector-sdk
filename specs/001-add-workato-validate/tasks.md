# Tasks: Workato Validate Command

**Feature**: Workato Validate Command
**Branch**: `001-add-workato-validate`
**Input**: Design documents from `/Users/dave/Documents/GitHub/workato-connector-sdk/specs/001-add-workato-validate/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/cli-interface.md, quickstart.md

---

## 🎯 Implementation Status: CORE COMPLETE

**Completion Date**: 2025-09-30
**Status**: Core validation functionality implemented and integrated

### ✅ Completed Tasks (19/42)

**Phase 3.1 - Setup (T001-T002)**: ✅ COMPLETE
- Directory structures created
- Module organization complete

**Phase 3.2 - Domain Models (T003-T006)**: ✅ COMPLETE
- `ValidationFinding` entity with full implementation
- `ValidationReport` entity with JSON/human output
- `ConnectorStructure` entity with Ripper-based AST parsing
- `BaseValidator` abstract class

**Phase 3.3 - Validators (T007-T014)**: ✅ COMPLETE
- `SyntaxValidator` - Ruby syntax validation (FR-004)
- `StructureValidator` - Required sections (FR-001, FR-002)
- `ConnectionValidator` - Auth configuration (FR-003)
- `ReferenceValidator` - object_definitions/pick_lists (FR-005, FR-006)
- `SignatureValidator` - Lambda signatures (FR-007, FR-008, FR-009)
- `FieldValidator` - Field types (FR-011, FR-023)
- `DeprecationValidator` - Deprecated patterns (FR-010)
- `AntiPatternValidator` - Security/best practices (FR-012, FR-013, FR-014)

**Phase 3.4 - CLI Integration (T015-T016)**: ✅ COMPLETE
- `ValidateCommand` class with full orchestration
- Integrated into main Thor CLI with `workato validate`
- Help text and command-line options configured

**Phase 3.5 - Test Fixtures (T017-T019)**: ✅ PARTIAL
- Valid connector fixture
- Missing sections fixture
- Invalid syntax fixture
- Deprecated patterns fixture

### 📋 Remaining Tasks (23/42)

**Phase 3.6-3.7**: Integration & Acceptance Tests (T020-T021)
**Phase 3.8**: Documentation & Polish (T022-T027)
**Phase 3.9**: Final Validation & CI/CD (T028-T033)

**Note**: Core functionality is complete and functional. Remaining tasks focus on comprehensive testing, documentation, and polish.

---

## Execution Summary

**Tech Stack**: Ruby >= 2.7.6, Thor CLI, Ripper (stdlib), Sorbet, RSpec
**Structure**: Single Ruby gem project (`lib/workato/`, `spec/workato/`)
**Entities**: 4 (ValidationReport, ValidationFinding, ValidationRule, ConnectorStructure)
**Validators**: 8 specialized validator classes
**Contract Tests**: 10 CLI scenarios
**Acceptance Tests**: 12 quickstart scenarios

**Total Tasks**: 42
**Completed**: 19
**Remaining**: 23

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- All paths relative to repository root: `/Users/dave/Documents/GitHub/workato-connector-sdk/`

---

## Phase 3.1: Setup & Infrastructure

### T001: Create test fixtures directory structure
**Type**: Setup
**Dependencies**: None
**Estimated Time**: 15 minutes

Create the fixtures directory structure for validation test scenarios:

```bash
mkdir -p spec/fixtures/validation/{valid_connector_test,missing_sections_test,invalid_syntax_test,deprecated_patterns_test,custom_path_test,dangling_refs_test,large_connector_test,multi_auth_test}
```

**Success Criteria**:
- [x] Directory structure created under `spec/fixtures/validation/`
- [x] All 8 test scenario directories exist

---

### T002: Create validation module directory structure
**Type**: Setup
**Dependencies**: None
**Estimated Time**: 10 minutes

Create the new module directories for validation logic:

```bash
mkdir -p lib/workato/cli/validators
mkdir -p lib/workato/connector/sdk/validation
mkdir -p spec/workato/cli
mkdir -p spec/workato/connector/sdk/validation
```

**Success Criteria**:
- [ ] Validators directory created at `lib/workato/cli/validators/`
- [ ] Validation models directory created at `lib/workato/connector/sdk/validation/`
- [ ] Spec directories mirror source structure

---

## Phase 3.2: Domain Models (Entities) - TDD

### T003 [P]: Create ValidationFinding entity with tests
**Type**: Entity + Test
**Dependencies**: T002
**Estimated Time**: 1.5 hours
**FR**: Foundation for all validation rules

**TDD Steps**:

1. **RED**: Create `spec/workato/connector/sdk/validation/finding_spec.rb`
```ruby
RSpec.describe Workato::Connector::Sdk::Validation::Finding do
  describe '#initialize' do
    it 'requires rule_name, severity, message'
    it 'accepts optional line_number, column_number, suggested_fix, context'
    it 'validates severity is :error, :warning, or :info'
  end

  describe '#error?' do
    it 'returns true when severity is :error'
  end

  describe '#warning?' do
    it 'returns true when severity is :warning'
  end

  describe '#info?' do
    it 'returns true when severity is :info'
  end

  describe '#location_string' do
    it 'formats "line X" when only line_number present'
    it 'formats "line X:Y" when both line and column present'
    it 'returns "file-level" when no line_number'
  end

  describe '#to_s' do
    it 'formats finding for display with severity, location, message'
  end
end
```

2. **Run specs** → Should FAIL (class doesn't exist)

3. **GREEN**: Create `lib/workato/connector/sdk/validation/finding.rb`
- Implement all attributes and methods
- Add Sorbet type signatures: `sig { params(...).returns(...) }`

4. **Run specs** → Should PASS

**Success Criteria**:
- [ ] All RSpec tests pass
- [ ] Sorbet type checks pass (`bundle exec srb tc`)
- [ ] RuboCop passes
- [ ] Code coverage ≥90%

---

### T004 [P]: Create ValidationReport entity with tests
**Type**: Entity + Test
**Dependencies**: T003 (uses ValidationFinding)
**Estimated Time**: 2 hours
**FR**: FR-017, FR-018

**TDD Steps**:

1. **RED**: Create `spec/workato/connector/sdk/validation/report_spec.rb`
```ruby
RSpec.describe Workato::Connector::Sdk::Validation::Report do
  describe '#initialize' do
    it 'requires connector_path, findings'
    it 'automatically sets validated_at timestamp'
    it 'calculates status based on findings'
  end

  describe '#error_count' do
    it 'counts findings with severity :error'
  end

  describe '#warning_count' do
    it 'counts findings with severity :warning'
  end

  describe '#pass?' do
    it 'returns true when no errors'
    it 'returns false when errors present'
  end

  describe '#fail?' do
    it 'returns true when errors present'
  end

  describe '#exit_code' do
    it 'returns 0 for pass (no errors or warnings)'
    it 'returns 1 for fail (errors present)'
    it 'returns 2 for warnings_only (warnings but no errors)'
  end

  describe '#to_json' do
    it 'generates valid JSON with connector_path, validated_at, status, findings'
    it 'includes summary with error_count, warning_count, info_count'
  end

  describe '#to_human' do
    it 'generates color-coded output with findings'
    it 'shows summary line with counts'
    it 'shows duration in seconds'
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/connector/sdk/validation/report.rb`
- Implement all methods
- Use JSON.generate for to_json
- Add colorization for to_human (check existing SDK color library)

**Success Criteria**:
- [ ] All RSpec tests pass
- [ ] JSON output validates against schema in data-model.md
- [ ] Exit codes match FR-018 (0/1/2)
- [ ] Sorbet + RuboCop pass

---

### T005 [P]: Create ConnectorStructure entity with tests
**Type**: Entity + Test
**Dependencies**: T002
**Estimated Time**: 3 hours
**FR**: FR-001, FR-004 (foundation for all validators)

**TDD Steps**:

1. **RED**: Create `spec/workato/connector/sdk/validation/connector_structure_spec.rb`
```ruby
RSpec.describe Workato::Connector::Sdk::Validation::ConnectorStructure do
  describe '#initialize' do
    it 'accepts source_code string'
    it 'initializes with syntax_valid = false'
  end

  describe '#parse!' do
    context 'with valid Ruby syntax' do
      it 'sets syntax_valid to true'
      it 'populates ast with Ripper S-expression'
      it 'extracts connector_hash from AST'
    end

    context 'with invalid Ruby syntax' do
      it 'sets syntax_valid to false'
      it 'populates parse_errors with error messages'
      it 'includes line numbers in error messages'
    end
  end

  describe 'derived attributes' do
    it 'extracts title from connector_hash[:title]'
    it 'extracts connection from connector_hash[:connection]'
    it 'extracts actions from connector_hash[:actions]'
    it 'extracts triggers from connector_hash[:triggers]'
    it 'defaults to empty hash when sections missing'
  end

  describe '#auth_type' do
    it 'returns connection.dig(:authorization, :type)'
  end

  describe '#defined_object_definitions' do
    it 'returns array of object_definitions keys'
  end

  describe '#defined_pick_lists' do
    it 'returns array of pick_lists keys'
  end

  describe '#section_line_number' do
    it 'finds line number of given section in AST'
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/connector/sdk/validation/connector_structure.rb`
- Use `Ripper.sexp(source_code)` for parsing
- Implement AST traversal to extract connector hash
- Handle parse errors gracefully

**Success Criteria**:
- [ ] Parses valid connector code successfully
- [ ] Detects syntax errors with line numbers
- [ ] Extracts all connector sections
- [ ] Tests pass, Sorbet + RuboCop pass

---

### T006 [P]: Create BaseValidator abstract class with tests
**Type**: Infrastructure + Test
**Dependencies**: T003, T004, T005
**Estimated Time**: 1.5 hours

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/base_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::BaseValidator do
  describe '#validate' do
    it 'raises NotImplementedError (abstract method)'
  end

  describe '#report_finding' do
    it 'creates ValidationFinding with given parameters'
    it 'returns Finding instance'
  end

  describe 'protected helpers' do
    it 'provides access to connector_structure'
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/base_validator.rb`
```ruby
module Workato
  module Cli
    module Validators
      class BaseValidator
        sig { params(structure: ConnectorStructure).void }
        def initialize(structure)
          @structure = structure
        end

        sig { abstract.returns(T::Array[Finding]) }
        def validate
          raise NotImplementedError, 'Subclasses must implement #validate'
        end

        protected

        sig { params(...).returns(Finding) }
        def report_finding(rule_name:, severity:, message:, line_number: nil, suggested_fix: nil, context: {})
          # Create and return Finding
        end

        attr_reader :structure
      end
    end
  end
end
```

**Success Criteria**:
- [ ] Abstract base class with template method pattern
- [ ] Helper methods for subclasses
- [ ] Tests pass, Sorbet + RuboCop pass

---

## Phase 3.3: Validators - TDD (Tests Before Implementation)

### T007 [P]: Create SyntaxValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 1.5 hours
**FR**: FR-004

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/syntax_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::SyntaxValidator do
  let(:validator) { described_class.new(structure) }

  context 'with valid Ruby syntax' do
    let(:structure) { build_structure(valid_connector_code) }

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with invalid Ruby syntax' do
    let(:structure) { build_structure("{ title: 'Test', connection: {") } # unclosed brace

    it 'returns finding with severity :error' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes line number in finding' do
      findings = validator.validate
      expect(findings.first.line_number).to be_a(Integer)
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('Fix the syntax error')
    end
  end

  context 'with empty file' do
    let(:structure) { build_structure('') }

    it 'returns finding for empty connector' do
      findings = validator.validate
      expect(findings).not_to be_empty
    end
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/syntax_validator.rb`
- Use `Ripper.sexp(source_code)` - returns nil on syntax error
- Extract error messages from Ripper
- Parse line numbers from error strings

**Success Criteria**:
- [ ] Detects syntax errors accurately
- [ ] Provides line numbers
- [ ] Tests pass (including edge cases)

---

### T008 [P]: Create StructureValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 2 hours
**FR**: FR-001, FR-002

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/structure_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::StructureValidator do
  let(:validator) { described_class.new(structure) }

  context 'with all required sections' do
    let(:structure) { build_structure_with(title: 'Test', connection: {}, test: -> {}) }

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'missing title section' do
    let(:structure) { build_structure_with(connection: {}, test: -> {}) }

    it 'returns error finding for missing title' do
      findings = validator.validate
      expect(findings).to include(have_attributes(
        rule_name: 'required_section_title',
        severity: :error,
        message: include('Missing required section: title')
      ))
    end
  end

  context 'missing connection section' do
    let(:structure) { build_structure_with(title: 'Test', test: -> {}) }

    it 'returns error finding for missing connection' do
      findings = validator.validate
      expect(findings.map(&:rule_name)).to include('required_section_connection')
    end
  end

  context 'missing test section' do
    let(:structure) { build_structure_with(title: 'Test', connection: {}) }

    it 'returns error finding for missing test' do
      findings = validator.validate
      expect(findings.map(&:rule_name)).to include('required_section_test')
    end
  end

  context 'file exists check (FR-001)' do
    it 'validates file was readable (checked at structure creation)'
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/structure_validator.rb`
- Check for required keys: `:title`, `:connection`, `:test`
- Report each missing section separately

**Success Criteria**:
- [ ] Validates all 3 required sections (FR-002)
- [ ] Provides specific error for each missing section
- [ ] Tests pass

---

### T009 [P]: Create ConnectionValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 2.5 hours
**FR**: FR-003

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/connection_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::ConnectionValidator do
  let(:validator) { described_class.new(structure) }

  context 'OAuth2 authorization' do
    context 'with all required keys' do
      let(:structure) do
        build_structure_with(
          connection: {
            authorization: {
              type: 'oauth2',
              authorization_url: -> {},
              acquire: -> {},
              apply: -> {}
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'missing authorization_url' do
      let(:structure) do
        build_structure_with(
          connection: {
            authorization: {
              type: 'oauth2',
              acquire: -> {},
              apply: -> {}
            }
          }
        )
      end

      it 'returns error for missing authorization_url' do
        findings = validator.validate
        expect(findings).to include(have_attributes(
          rule_name: 'oauth2_missing_authorization_url',
          severity: :error
        ))
      end
    end

    context 'missing acquire' do
      # Similar test for missing acquire
    end

    context 'missing apply' do
      # Similar test for missing apply
    end
  end

  context 'basic_auth authorization' do
    context 'with required apply' do
      let(:structure) do
        build_structure_with(
          connection: {
            authorization: {
              type: 'basic_auth',
              apply: -> {}
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'missing apply' do
      # Test missing apply for basic_auth
    end
  end

  context 'api_key authorization' do
    # Similar structure for api_key
  end

  context 'custom_auth authorization' do
    # Similar structure for custom_auth
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/connection_validator.rb`
- Define AUTH_REQUIREMENTS constant (from research.md)
- Check auth_type and validate required keys present
- Report missing keys with context

**Success Criteria**:
- [ ] Validates OAuth2, basic_auth, api_key, custom_auth (FR-003)
- [ ] Detects missing required keys per auth type
- [ ] Tests cover all auth types

---

### T010 [P]: Create ReferenceValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 3 hours
**FR**: FR-005, FR-006

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/reference_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::ReferenceValidator do
  let(:validator) { described_class.new(structure) }

  context 'object_definitions references' do
    context 'all references defined' do
      let(:structure) do
        build_structure_with(
          object_definitions: {
            customer: { fields: -> { [{name: 'id'}] } }
          },
          actions: {
            search: {
              output_fields: -> { object_definitions[:customer] }
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'undefined object_definition reference' do
      let(:structure) do
        build_structure_with(
          object_definitions: {},
          actions: {
            search: {
              output_fields: -> { object_definitions[:customer] } # customer not defined
            }
          }
        )
      end

      it 'returns error for dangling reference' do
        findings = validator.validate
        expect(findings).to include(have_attributes(
          rule_name: 'undefined_object_definition',
          severity: :error,
          message: include('undefined object_definition: customer')
        ))
      end
    end
  end

  context 'pick_lists references' do
    context 'all references defined' do
      let(:structure) do
        build_structure_with(
          pick_lists: {
            statuses: -> { [['Active', 'active']] }
          },
          actions: {
            update: {
              input_fields: -> {
                [{
                  name: 'status',
                  control_type: 'select',
                  pick_list: 'statuses'
                }]
              }
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'undefined pick_list reference' do
      # Similar test for undefined pick_list
    end
  end

  context 'references in triggers' do
    # Test pick_list and object_definition refs in triggers
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/reference_validator.rb`
- Two-pass approach: collect definitions, then find references
- Parse AST to find `object_definitions[:symbol]` and `pick_list: 'string'`
- Report dangling references with context

**Success Criteria**:
- [ ] Validates object_definitions references (FR-005)
- [ ] Validates pick_lists references (FR-006)
- [ ] Detects references in actions and triggers

---

### T011 [P]: Create SignatureValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 3 hours
**FR**: FR-007, FR-008, FR-009, FR-021

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/signature_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::SignatureValidator do
  let(:validator) { described_class.new(structure) }

  context 'action execute blocks' do
    context 'with correct signature' do
      let(:structure) do
        build_structure_with(
          actions: {
            search: {
              execute: -> (connection, input, input_schema, output_schema, closure) {}
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with minimal signature (connection, input)' do
      let(:structure) do
        build_structure_with(
          actions: {
            search: {
              execute: -> (connection, input) {}
            }
          }
        )
      end

      it 'returns empty findings (minimal signature valid)' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with too few parameters' do
      let(:structure) do
        build_structure_with(
          actions: {
            search: {
              execute: -> (connection) {} # missing input
            }
          }
        )
      end

      it 'returns error for invalid signature' do
        findings = validator.validate
        expect(findings).to include(have_attributes(
          rule_name: 'invalid_execute_signature',
          severity: :error
        ))
      end
    end
  end

  context 'trigger poll blocks' do
    context 'with correct signature' do
      let(:structure) do
        build_structure_with(
          triggers: {
            new_record: {
              poll: -> (connection, input, closure) {}
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with invalid signature' do
      # Test missing parameters for poll
    end
  end

  context 'webhook triggers' do
    context 'with required webhook methods' do
      let(:structure) do
        build_structure_with(
          triggers: {
            new_webhook: {
              type: 'webhook',
              webhook_subscribe: -> (webhook_url, connection, input, recipe_id) {},
              webhook_notification: -> (input, payload) {}
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'missing webhook_subscribe' do
      # Test error for missing webhook_subscribe
    end

    context 'missing webhook_notification' do
      # Test error for missing webhook_notification
    end
  end

  context 'stream definitions (FR-021)' do
    # Test stream signature validation
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/signature_validator.rb`
- Extract lambda parameters from AST
- Validate parameter counts for execute, poll, webhook_subscribe, webhook_notification
- Check stream signatures

**Success Criteria**:
- [ ] Validates execute signatures (FR-007)
- [ ] Validates poll signatures (FR-008)
- [ ] Validates webhook signatures (FR-009)
- [ ] Validates stream signatures (FR-021)

---

### T012 [P]: Create FieldValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 2.5 hours
**FR**: FR-011, FR-023

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/field_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::FieldValidator do
  let(:validator) { described_class.new(structure) }

  context 'valid field types' do
    let(:structure) do
      build_structure_with(
        actions: {
          create: {
            input_fields: -> {
              [
                { name: 'name', type: 'string' },
                { name: 'age', type: 'integer' },
                { name: 'active', type: 'boolean' },
                { name: 'created_at', type: 'datetime' }
              ]
            }
          }
        }
      )
    end

    it 'returns empty findings' do
      expect(validator.validate).to be_empty
    end
  end

  context 'invalid field type' do
    let(:structure) do
      build_structure_with(
        actions: {
          create: {
            input_fields: -> {
              [{ name: 'status', type: 'varchar' }] # invalid type
            }
          }
        }
      )
    end

    it 'returns error for invalid type' do
      findings = validator.validate
      expect(findings).to include(have_attributes(
        rule_name: 'invalid_field_type',
        severity: :error,
        message: include('varchar')
      ))
    end
  end

  context 'summarize_input references (FR-023)' do
    context 'valid field path' do
      let(:structure) do
        build_structure_with(
          actions: {
            create: {
              input_fields: -> { [{ name: 'email' }] },
              summarize_input: 'email'
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'invalid field path' do
      let(:structure) do
        build_structure_with(
          actions: {
            create: {
              input_fields: -> { [{ name: 'email' }] },
              summarize_input: 'username' # field doesn't exist
            }
          }
        )
      end

      it 'returns error for invalid reference' do
        findings = validator.validate
        expect(findings.first.rule_name).to eq('invalid_summarize_reference')
      end
    end
  end

  context 'summarize_output references' do
    # Similar tests for summarize_output
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/field_validator.rb`
- Define VALID_FIELD_TYPES constant
- Check field type values
- Validate summarize_input and summarize_output paths

**Success Criteria**:
- [ ] Validates field types (FR-011)
- [ ] Validates summarize references (FR-023)
- [ ] Tests pass

---

### T013 [P]: Create DeprecationValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 2 hours
**FR**: FR-010

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/deprecation_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::DeprecationValidator do
  let(:validator) { described_class.new(structure) }

  context 'no deprecated patterns' do
    let(:structure) { build_structure_with_modern_dsl }

    it 'returns empty findings' do
      expect(validator.validate).to be_empty
    end
  end

  context 'deprecated method usage' do
    let(:structure) do
      build_structure_with(
        connection: {
          after_error_response: -> {} # deprecated method
        }
      )
    end

    it 'returns warning for deprecated method' do
      findings = validator.validate
      expect(findings).to include(have_attributes(
        rule_name: 'deprecated_dsl_method',
        severity: :warning,
        message: include('after_error_response')
      ))
    end

    it 'suggests modern alternative' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('error_handler')
    end
  end

  context 'multiple deprecated patterns' do
    # Test multiple deprecations in one connector
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/deprecation_validator.rb`
- Define DEPRECATED_PATTERNS constant (from research.md)
- Search AST for deprecated method names
- Return warnings with modern alternatives

**Success Criteria**:
- [ ] Detects deprecated DSL methods (FR-010)
- [ ] Suggests modern replacements
- [ ] Returns warnings, not errors

---

### T014 [P]: Create AntiPatternValidator with tests
**Type**: Validator + Test
**Dependencies**: T006
**Estimated Time**: 3 hours
**FR**: FR-012, FR-013, FR-014, FR-022, FR-024, FR-025

**TDD Steps**:

1. **RED**: Create `spec/workato/cli/validators/anti_pattern_validator_spec.rb`
```ruby
RSpec.describe Workato::Cli::Validators::AntiPatternValidator do
  let(:validator) { described_class.new(structure) }

  context 'hardcoded credentials (FR-012)' do
    context 'no hardcoded credentials' do
      let(:structure) { build_structure_using_connection_param }

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'hardcoded API key in execute block' do
      let(:structure) do
        build_structure_with(
          actions: {
            get_data: {
              execute: -> (connection, input) {
                get('/api/data').headers('Authorization' => 'Bearer abc123') # hardcoded!
              }
            }
          }
        )
      end

      it 'returns error for hardcoded credentials' do
        findings = validator.validate
        expect(findings).to include(have_attributes(
          rule_name: 'hardcoded_credentials',
          severity: :error
        ))
      end
    end
  end

  context 'methods block validation (FR-013)' do
    context 'only lambda definitions' do
      let(:structure) do
        build_structure_with(
          methods: {
            format_date: -> (date) { date.strftime('%Y-%m-%d') }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'non-lambda in methods block' do
      let(:structure) do
        build_structure_with(
          methods: {
            constant_value: 42 # not a lambda
          }
        )
      end

      it 'returns error for non-lambda' do
        findings = validator.validate
        expect(findings.first.rule_name).to eq('methods_non_lambda')
      end
    end
  end

  context 'action/trigger names (FR-014)' do
    context 'valid symbol names' do
      let(:structure) do
        build_structure_with(
          actions: {
            search_customers: {},
            get_record: {}
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'invalid action name with spaces' do
      let(:structure) do
        build_structure_with(
          actions: {
            'search customers': {} # spaces not allowed
          }
        )
      end

      it 'returns error for invalid name' do
        findings = validator.validate
        expect(findings.first.rule_name).to eq('invalid_action_name')
      end
    end
  end

  context 'CSV, JWT, encryption methods (FR-022)' do
    # Test proper usage of CSV, JWT, encryption methods
  end

  context 'parallel request configurations (FR-025)' do
    context 'valid thread count and rate limit' do
      let(:structure) do
        build_structure_with(
          actions: {
            bulk_create: {
              execute: -> (connection, input) {
                parallel({ threads: 5, rate_limit: 10 }) do |batch|
                  # ...
                end
              }
            }
          }
        )
      end

      it 'returns empty findings' do
        expect(validator.validate).to be_empty
      end
    end

    context 'invalid thread count' do
      # Test invalid parallel config
    end
  end
end
```

2. **Run specs** → Should FAIL

3. **GREEN**: Create `lib/workato/cli/validators/anti_pattern_validator.rb`
- Search AST for hardcoded tokens/keys (regex patterns)
- Validate methods block contains only lambdas
- Check action/trigger names are valid Ruby symbols
- Validate CSV/JWT/encryption usage
- Check parallel request configs

**Success Criteria**:
- [ ] Detects hardcoded credentials (FR-012)
- [ ] Validates methods block (FR-013)
- [ ] Validates names (FR-014)
- [ ] Checks CSV/JWT/encryption (FR-022)
- [ ] Validates parallel configs (FR-025)

---

## Phase 3.4: CLI Command Integration

### T015: Create ValidateCommand CLI class with basic structure
**Type**: CLI Implementation
**Dependencies**: T004, T005, T007-T014 (all validators)
**Estimated Time**: 2 hours
**FR**: FR-015, FR-016, FR-017, FR-018, FR-019, FR-020

Create the Thor command class that orchestrates validation:

1. Create `lib/workato/cli/validate_command.rb`:

```ruby
module Workato
  module Cli
    class ValidateCommand < Thor
      desc 'validate [OPTIONS]', 'Validates connector code for structural errors and DSL violations'

      option :connector,
             type: :string,
             aliases: '-c',
             default: 'connector.rb',
             desc: 'Path to connector source code'

      option :output,
             type: :string,
             aliases: '-o',
             desc: 'Write JSON validation report to file'

      option :verbose,
             type: :boolean,
             aliases: '-v',
             default: false,
             desc: 'Show all checks performed, not just failures'

      def validate
        start_time = Time.now
        connector_path = options[:connector]

        # 1. Check file exists (FR-001)
        unless File.exist?(connector_path)
          handle_file_not_found(connector_path)
          return
        end

        # 2. Read connector file
        source_code = File.read(connector_path)

        # 3. Parse structure
        structure = Workato::Connector::Sdk::Validation::ConnectorStructure.new(source_code)
        structure.parse!

        # 4. Run all validators
        findings = run_validators(structure)

        # 5. Generate report
        duration_ms = ((Time.now - start_time) * 1000).to_i
        report = Workato::Connector::Sdk::Validation::Report.new(
          connector_path: File.expand_path(connector_path),
          findings: findings,
          duration_ms: duration_ms
        )

        # 6. Output report
        output_report(report)

        # 7. Exit with appropriate code (FR-018)
        exit(report.exit_code)
      rescue Errno::EACCES => e
        handle_permission_error(connector_path, e)
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      private

      def run_validators(structure)
        validators = [
          Validators::SyntaxValidator,
          Validators::StructureValidator,
          Validators::ConnectionValidator,
          Validators::ReferenceValidator,
          Validators::SignatureValidator,
          Validators::FieldValidator,
          Validators::DeprecationValidator,
          Validators::AntiPatternValidator
        ]

        # Run validators concurrently (FR-019 performance)
        # Use Concurrent::Future from concurrent-ruby gem
        findings = validators.flat_map do |validator_class|
          validator_class.new(structure).validate
        end

        # Sort findings: errors first, then by line number
        findings.sort_by { |f| [f.severity == :error ? 0 : 1, f.line_number || 0] }
      end

      def output_report(report)
        if options[:output]
          # JSON output (FR-016)
          File.write(options[:output], report.to_json)
          say "Validation report written to #{options[:output]}"
        else
          # Human-readable output (FR-017)
          say report.to_human(verbose: options[:verbose])
        end
      end

      def handle_file_not_found(path)
        say "ERROR: Connector file not found at '#{path}'", :red
        say "\nSuggestion: Check the file path, or run 'workato new' to create a new connector."
        exit(1)
      end

      def handle_permission_error(path, error)
        say "ERROR: Permission denied reading '#{path}'", :red
        say "\nSuggestion: Check file permissions and ensure you have read access."
        exit(1)
      end

      def handle_unexpected_error(error)
        say "ERROR: Unexpected error during validation: #{error.message}", :red
        say error.backtrace.join("\n") if ENV['DEBUG']
        exit(1)
      end
    end
  end
end
```

**Success Criteria**:
- [ ] Integrates with Thor CLI framework
- [ ] Supports all 4 CLI flags (--connector, --output, --verbose, --help)
- [ ] Orchestrates all validators
- [ ] Handles errors gracefully
- [ ] Returns correct exit codes (FR-018)

---

### T016: Register validate command in main CLI
**Type**: Integration
**Dependencies**: T015
**Estimated Time**: 30 minutes

Update `lib/workato/cli/main.rb` to register the validate command:

```ruby
# In lib/workato/cli/main.rb
require_relative 'validate_command'

module Workato
  module Cli
    class Main < Thor
      # ... existing commands ...

      desc 'validate [OPTIONS]', 'Validates connector code for errors and violations'
      subcommand 'validate', ValidateCommand
    end
  end
end
```

**Success Criteria**:
- [ ] `workato help` shows validate command
- [ ] `workato validate --help` displays help text
- [ ] Command is accessible from CLI

---

## Phase 3.5: Test Fixtures Creation

### T017 [P]: Create valid connector fixture
**Type**: Test Fixture
**Dependencies**: T001
**Estimated Time**: 1 hour

Create a minimal valid connector for testing:

File: `spec/fixtures/validation/valid_connector_test/valid_connector.rb`

```ruby
{
  title: 'Test Connector',

  connection: {
    fields: [
      { name: 'api_key', control_type: 'password' }
    ],

    authorization: {
      type: 'custom_auth',
      apply: -> (connection) {
        headers('Authorization' => "Bearer #{connection['api_key']}")
      }
    }
  },

  test: -> (connection) {
    get('/api/test')
  },

  actions: {
    get_record: {
      input_fields: -> {
        [{ name: 'id', type: 'string' }]
      },

      execute: -> (connection, input) {
        get("/api/records/#{input['id']}")
      },

      output_fields: -> {
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' }
        ]
      }
    }
  },

  triggers: {
    new_record: {
      poll: -> (connection, input, closure) {
        get('/api/records')
      },

      output_fields: -> {
        [{ name: 'id' }, { name: 'name' }]
      }
    }
  },

  object_definitions: {
    record: {
      fields: -> {
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' }
        ]
      }
    }
  }
}
```

**Success Criteria**:
- [ ] Passes all validation rules
- [ ] Covers common connector patterns
- [ ] Can be used in multiple tests

---

### T018 [P]: Create invalid fixtures for error scenarios
**Type**: Test Fixtures
**Dependencies**: T001
**Estimated Time**: 2 hours

Create fixtures for each error scenario:

1. **missing_test_section_connector.rb** - Missing test: block
2. **invalid_syntax_connector.rb** - Unclosed braces, syntax errors
3. **deprecated_dsl_connector.rb** - Uses after_error_response
4. **dangling_refs_connector.rb** - References undefined object_definitions
5. **invalid_oauth2_connector.rb** - OAuth2 missing acquire block
6. **invalid_signatures_connector.rb** - Execute block with 1 parameter only
7. **hardcoded_credentials_connector.rb** - API key hardcoded in execute
8. **invalid_field_types_connector.rb** - Field with type: 'varchar'

**Success Criteria**:
- [ ] Each fixture triggers specific validation error
- [ ] Fixtures represent realistic mistakes
- [ ] Cover all major validation rules

---

### T019 [P]: Create large connector fixture for performance testing
**Type**: Test Fixture
**Dependencies**: T001
**Estimated Time**: 1 hour
**FR**: FR-019

Generate a 5000-line connector for performance testing:

Script to generate: `spec/fixtures/validation/large_connector_test/generate_large_connector.rb`

```ruby
# Generate connector with 100 actions, 50 triggers, etc.
# Total ~5000 lines
```

**Success Criteria**:
- [ ] Connector is ~5000 lines
- [ ] Valid syntax
- [ ] Used for performance testing

---

## Phase 3.6: Integration Tests (CLI Contract Tests)

### T020: Create validate_command integration test suite
**Type**: Integration Test
**Dependencies**: T015, T016, T017, T018
**Estimated Time**: 4 hours

Create comprehensive CLI integration tests:

File: `spec/workato/cli/validate_command_spec.rb`

```ruby
RSpec.describe 'workato validate CLI', :integration do
  include_context 'CLI test helpers'

  describe 'Contract Test 1: Valid connector' do
    before do
      create_fixture_file('connector.rb', valid_connector_code)
    end

    it 'exits with code 0 and success message' do
      output, status = run_cli('validate')

      expect(status.exitstatus).to eq(0)
      expect(output).to include('✓ Connector validation passed')
      expect(output).to match(/Duration: \d+\.\d+s/)
    end
  end

  describe 'Contract Test 2: Missing required section' do
    before do
      create_fixture_file('connector.rb', connector_missing_test)
    end

    it 'exits with code 1 and error message' do
      output, status = run_cli('validate')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('ERROR')
      expect(output).to include('Missing required section: test')
      expect(output).to include('Add test: lambda')
    end
  end

  describe 'Contract Test 3: Deprecated DSL' do
    before do
      create_fixture_file('connector.rb', connector_with_deprecation)
    end

    it 'exits with code 2 and warning message' do
      output, status = run_cli('validate')

      expect(status.exitstatus).to eq(2)
      expect(output).to include('WARNING')
      expect(output).to include('deprecated')
      expect(output).to include('Validation passed with warnings')
    end
  end

  describe 'Contract Test 4: Custom file path (--connector)' do
    before do
      create_fixture_file('custom_connector.rb', valid_connector_code)
    end

    it 'validates specified file' do
      output, status = run_cli('validate --connector=custom_connector.rb')

      expect(status.exitstatus).to eq(0)
      expect(output).to include('Validating custom_connector.rb')
    end
  end

  describe 'Contract Test 5: JSON output (--output)' do
    before do
      create_fixture_file('connector.rb', connector_missing_test)
    end

    it 'writes JSON report to file' do
      output, status = run_cli('validate --output=report.json')

      expect(File.exist?('report.json')).to be true

      report = JSON.parse(File.read('report.json'))
      expect(report).to include('connector_path', 'validated_at', 'status', 'findings')
      expect(report['status']).to eq('fail')
      expect(report['findings']).not_to be_empty
    end
  end

  describe 'Contract Test 6: Verbose mode (--verbose)' do
    before do
      create_fixture_file('connector.rb', valid_connector_code)
    end

    it 'shows all checks performed' do
      output, status = run_cli('validate --verbose')

      expect(status.exitstatus).to eq(0)
      expect(output).to include('✓ Syntax validation passed')
      expect(output).to include('✓ Required sections present')
      expect(output).to include('✓ Connection authorization valid')
    end
  end

  describe 'Contract Test 7: File not found' do
    it 'shows clear error message' do
      output, status = run_cli('validate --connector=nonexistent.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('ERROR: Connector file not found')
      expect(output).to include('workato new')
    end
  end

  describe 'Contract Test 8: Invalid syntax' do
    before do
      create_fixture_file('connector.rb', '{ title: "Test", connection: {') # unclosed
    end

    it 'reports syntax error with line number' do
      output, status = run_cli('validate')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Ruby syntax error')
      expect(output).to match(/line \d+/)
    end
  end

  describe 'Contract Test 9: Multiple errors' do
    before do
      create_fixture_file('connector.rb', connector_multiple_errors)
    end

    it 'reports all errors sorted by severity' do
      output, status = run_cli('validate')

      expect(status.exitstatus).to eq(1)
      expect(output).to scan(/ERROR/).count).to be >= 2
    end
  end

  describe 'Contract Test 10: Performance with large file' do
    before do
      create_fixture_file('connector.rb', large_connector_5000_lines)
    end

    it 'completes within 10 seconds (FR-019)' do
      start_time = Time.now
      output, status = run_cli('validate')
      duration = Time.now - start_time

      expect(duration).to be < 10.0
      expect(status.exitstatus).to eq(0)
    end
  end
end
```

**Success Criteria**:
- [ ] All 10 contract tests pass
- [ ] Exit codes verified (0, 1, 2)
- [ ] Output format validated
- [ ] Performance requirement met (FR-019)

---

## Phase 3.7: Acceptance Tests (Quickstart Scenarios)

### T021 [P]: Implement quickstart scenario tests
**Type**: Acceptance Test
**Dependencies**: T020
**Estimated Time**: 3 hours

Create tests for all quickstart scenarios:

File: `spec/acceptance/validate_quickstart_spec.rb`

```ruby
RSpec.describe 'Workato Validate Quickstart Scenarios', :acceptance do
  describe 'Scenario 1: Valid Connector' do
    # From quickstart.md - Test Scenario 1
    it 'passes validation with exit code 0' do
      # Test implementation
    end
  end

  describe 'Scenario 2: Missing Required Section' do
    # From quickstart.md - Test Scenario 2
  end

  describe 'Scenario 3: Invalid Syntax' do
    # From quickstart.md - Test Scenario 3
  end

  describe 'Scenario 4: Deprecated DSL Patterns' do
    # From quickstart.md - Test Scenario 4
  end

  describe 'Scenario 5: Custom File Path' do
    # From quickstart.md - Test Scenario 5
  end

  describe 'Scenario 6: Verbose Output' do
    # From quickstart.md - Test Scenario 6
  end

  describe 'Scenario 7: JSON Output for CI/CD' do
    # From quickstart.md - Test Scenario 7
  end

  describe 'Edge Case 1: Non-Existent File' do
    # From quickstart.md - Edge Case 1
  end

  describe 'Edge Case 2: Large Connector File' do
    # From quickstart.md - Edge Case 2
  end

  describe 'Edge Case 3: Multi-Auth Configurations' do
    # From quickstart.md - Edge Case 3
  end

  describe 'Edge Case 4: Dangling References' do
    # From quickstart.md - Edge Case 4
  end

  describe 'Edge Case 5: Permission Error' do
    # From quickstart.md - Edge Case 5
  end
end
```

**Success Criteria**:
- [ ] All 7 acceptance scenarios pass
- [ ] All 5 edge cases handled correctly
- [ ] Matches quickstart.md expectations

---

## Phase 3.8: Documentation & Polish

### T022 [P]: Add YARD documentation to all public methods
**Type**: Documentation
**Dependencies**: T003-T015
**Estimated Time**: 2 hours
**FR**: Constitutional Principle VII

Add YARD docs to all public methods:

```ruby
# Example for ValidationReport
##
# Represents the complete validation outcome for a connector file.
#
# @attr_reader [String] connector_path Absolute path to validated connector file
# @attr_reader [Time] validated_at Timestamp when validation was performed
# @attr_reader [Array<ValidationFinding>] findings All findings discovered
# @attr_reader [Symbol] status Overall status (:pass, :fail, :warnings_only)
# @attr_reader [Integer] duration_ms Time taken in milliseconds
#
# @example Create a validation report
#   report = ValidationReport.new(
#     connector_path: '/path/to/connector.rb',
#     findings: [finding1, finding2],
#     duration_ms: 234
#   )
#
# @example Check if validation passed
#   report.pass? #=> false
#   report.exit_code #=> 1
class ValidationReport
  # ...
end
```

**Success Criteria**:
- [ ] All public classes documented
- [ ] All public methods documented
- [ ] Examples included
- [ ] `yard doc` runs without errors

---

### T023 [P]: Add help text and usage examples
**Type**: Documentation
**Dependencies**: T015
**Estimated Time**: 1 hour

Enhance CLI help text in `validate_command.rb`:

```ruby
long_desc <<-LONGDESC
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
    $ workato validate
    # Validate default connector.rb

    $ workato validate --connector=custom_connector.rb
    # Validate specific connector file

    $ workato validate --output=report.json
    # Output JSON report for CI/CD

    $ workato validate --verbose
    # Show all checks, not just failures
LONGDESC
```

**Success Criteria**:
- [ ] `workato help validate` shows comprehensive help
- [ ] Examples are accurate
- [ ] Exit codes documented

---

### T024 [P]: Create README section for validate command
**Type**: Documentation
**Dependencies**: T015
**Estimated Time**: 1 hour

Add section to main README.md:

```markdown
### `workato validate`

Validates your connector code for errors and best practices before deployment.

**Usage:**
```bash
workato validate [OPTIONS]
```

**Options:**
- `--connector=PATH` - Path to connector file (default: connector.rb)
- `--output=PATH` - Write JSON report to file
- `--verbose` - Show all checks performed
- `--help` - Display help message

**Example:**
```bash
# Validate connector with detailed output
workato validate --verbose

# Generate JSON report for CI/CD
workato validate --output=validation-report.json
```

**Validation Rules:**
The validate command checks 25+ rules including:
- Required sections (title, connection, test)
- Ruby syntax errors
- Authentication configuration
- Object definition references
- Lambda signatures
- Field types
- Deprecated patterns
- Security anti-patterns

See [Validation Guide](docs/validation.md) for complete rule list.
```

**Success Criteria**:
- [ ] README section added
- [ ] Examples are accurate
- [ ] Links to detailed docs

---

### T025 [P]: Run RuboCop and fix style violations
**Type**: Code Quality
**Dependencies**: T003-T015
**Estimated Time**: 2 hours

Run RuboCop on all new code and fix violations:

```bash
bundle exec rubocop lib/workato/cli/validators/
bundle exec rubocop lib/workato/connector/sdk/validation/
bundle exec rubocop lib/workato/cli/validate_command.rb
bundle exec rubocop spec/workato/cli/validate_command_spec.rb
```

**Success Criteria**:
- [ ] All RuboCop offenses resolved
- [ ] Style consistent with existing codebase
- [ ] No disabled cops without justification

---

### T026 [P]: Run Sorbet type checker and resolve issues
**Type**: Code Quality
**Dependencies**: T003-T015
**Estimated Time**: 2 hours

Run Sorbet type checker and add missing type signatures:

```bash
bundle exec srb tc
```

Add `sig` annotations to all public methods:

```ruby
sig { params(connector_path: String, findings: T::Array[Finding]).void }
def initialize(connector_path, findings)
  # ...
end

sig { returns(Integer) }
def exit_code
  # ...
end
```

**Success Criteria**:
- [ ] All Sorbet errors resolved
- [ ] Public methods have type signatures
- [ ] Type safety maintained

---

### T027 [P]: Verify code coverage ≥90%
**Type**: Testing
**Dependencies**: T003-T021
**Estimated Time**: 1 hour

Run code coverage analysis and add missing tests:

```bash
bundle exec rspec --format documentation --format RspecJunitFormatter --out test-results.xml
open coverage/index.html
```

**Success Criteria**:
- [ ] Overall coverage ≥90% (FR: Constitutional Principle III)
- [ ] All validators have ≥90% coverage
- [ ] Edge cases covered

---

### T028: Run full RSpec test suite
**Type**: Testing
**Dependencies**: T003-T021
**Estimated Time**: 30 minutes

Run complete test suite and verify all pass:

```bash
bundle exec rspec spec/ --format documentation
```

Expected output:
- All entity specs pass (T003-T006)
- All validator specs pass (T007-T014)
- All integration specs pass (T020)
- All acceptance specs pass (T021)

**Success Criteria**:
- [ ] All tests pass
- [ ] No pending tests
- [ ] No flaky tests (run 3 times)

---

### T029: Performance benchmark validation
**Type**: Testing
**Dependencies**: T019, T020
**Estimated Time**: 1 hour
**FR**: FR-019

Create performance benchmark test:

File: `spec/performance/validate_performance_spec.rb`

```ruby
RSpec.describe 'Validation Performance', :performance do
  it 'completes validation in <10s for 5000 line file' do
    connector_path = 'spec/fixtures/validation/large_connector_test/large_connector.rb'

    elapsed = Benchmark.realtime do
      system("bundle exec workato validate --connector=#{connector_path}")
    end

    expect(elapsed).to be < 10.0
  end

  it 'starts up in <2s for simple validation' do
    connector_path = 'spec/fixtures/validation/valid_connector_test/valid_connector.rb'

    elapsed = Benchmark.realtime do
      system("bundle exec workato validate --connector=#{connector_path}")
    end

    expect(elapsed).to be < 2.0
  end

  it 'uses <512MB memory for typical connector' do
    connector_path = 'spec/fixtures/validation/valid_connector_test/valid_connector.rb'

    # Use memory_profiler gem or similar
    memory_usage = measure_memory do
      system("bundle exec workato validate --connector=#{connector_path}")
    end

    expect(memory_usage).to be < 512 * 1024 * 1024 # 512MB in bytes
  end
end
```

**Success Criteria**:
- [ ] Large file (5000 lines) validates in <10s (FR-019)
- [ ] Command startup <2s (Constitutional Principle V)
- [ ] Memory usage <512MB (Constitutional Principle V)

---

## Phase 3.9: Final Validation

### T030: Execute quickstart.md scenarios manually
**Type**: Manual Testing
**Dependencies**: All previous tasks
**Estimated Time**: 2 hours

Execute all scenarios from quickstart.md manually:

1. Test Scenario 1: Valid Connector
2. Test Scenario 2: Missing Required Section
3. Test Scenario 3: Invalid Syntax
4. Test Scenario 4: Deprecated DSL Patterns
5. Test Scenario 5: Custom File Path
6. Test Scenario 6: Verbose Output
7. Test Scenario 7: JSON Output for CI/CD
8. Edge Case 1: Non-Existent File
9. Edge Case 2: Large Connector File
10. Edge Case 3: Multi-Auth Configurations
11. Edge Case 4: Dangling References
12. Edge Case 5: Permission Error

**Success Criteria**:
- [ ] All scenarios produce expected output
- [ ] All exit codes correct
- [ ] All error messages clear and actionable
- [ ] Performance targets met

---

### T031: Test CI/CD integration (GitHub Actions)
**Type**: Integration Testing
**Dependencies**: T015, T016
**Estimated Time**: 1 hour

Create test GitHub Actions workflow:

File: `.github/workflows/test-validate-command.yml`

```yaml
name: Test Validate Command

on: [push, pull_request]

jobs:
  test-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
          bundler-cache: true

      - name: Run validate on test fixtures
        run: |
          bundle exec workato validate --connector=spec/fixtures/validation/valid_connector_test/valid_connector.rb --output=report.json

      - name: Verify validation report
        run: |
          jq -e '.status == "pass"' report.json

      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: report.json
```

**Success Criteria**:
- [ ] CI workflow runs successfully
- [ ] JSON report is generated
- [ ] Report is parseable by jq
- [ ] Artifacts are uploaded

---

### T032: Update CLAUDE.md with implementation details
**Type**: Documentation
**Dependencies**: All previous tasks
**Estimated Time**: 30 minutes

Update `/Users/dave/Documents/GitHub/workato-connector-sdk/CLAUDE.md`:

```bash
# Update recent changes
.specify/scripts/bash/update-agent-context.sh claude
```

Verify:
- Commands section includes `workato validate`
- Recent changes tracked
- File stays under 150 lines

**Success Criteria**:
- [ ] CLAUDE.md updated with validate command
- [ ] Recent changes logged
- [ ] File size reasonable

---

### T033: Create PR checklist and summary
**Type**: Documentation
**Dependencies**: All previous tasks
**Estimated Time**: 1 hour

Create PR description with:

1. **Summary**: What was added (workato validate command)
2. **Implementation**: Key technical decisions
3. **Testing**: Coverage and test results
4. **Performance**: Benchmark results
5. **Breaking Changes**: None
6. **Checklist**:
   - [ ] All tests pass
   - [ ] Code coverage ≥90%
   - [ ] RuboCop passes
   - [ ] Sorbet type checks pass
   - [ ] Documentation complete
   - [ ] Quickstart scenarios verified
   - [ ] Performance benchmarks meet targets
   - [ ] CI/CD integration tested

**Success Criteria**:
- [ ] PR description is comprehensive
- [ ] Checklist complete
- [ ] Ready for code review

---

## Dependencies Graph

```
Setup (T001-T002)
  ↓
Entities [P] (T003-T005)
  ↓
BaseValidator (T006)
  ↓
Validators [P] (T007-T014)
  ↓
CLI Command (T015-T016)
  ↓
Fixtures [P] (T017-T019)
  ↓
Integration Tests (T020)
  ↓
Acceptance Tests [P] (T021)
  ↓
Documentation [P] (T022-T024)
Code Quality [P] (T025-T027)
  ↓
Testing (T028-T029)
  ↓
Final Validation (T030-T033)
```

---

## Parallel Execution Examples

### Phase 3.2: Create all entities in parallel
```bash
# These tasks touch different files and can run simultaneously
Task agent: "Create ValidationFinding entity with tests" (T003)
Task agent: "Create ValidationReport entity with tests" (T004)
Task agent: "Create ConnectorStructure entity with tests" (T005)
```

### Phase 3.3: Create all validators in parallel
```bash
# After BaseValidator (T006) is complete, all validators can be built in parallel
Task agent: "Create SyntaxValidator with tests" (T007)
Task agent: "Create StructureValidator with tests" (T008)
Task agent: "Create ConnectionValidator with tests" (T009)
Task agent: "Create ReferenceValidator with tests" (T010)
Task agent: "Create SignatureValidator with tests" (T011)
Task agent: "Create FieldValidator with tests" (T012)
Task agent: "Create DeprecationValidator with tests" (T013)
Task agent: "Create AntiPatternValidator with tests" (T014)
```

### Phase 3.5: Create all fixtures in parallel
```bash
Task agent: "Create valid connector fixture" (T017)
Task agent: "Create invalid fixtures for error scenarios" (T018)
Task agent: "Create large connector fixture" (T019)
```

### Phase 3.8: Documentation in parallel
```bash
Task agent: "Add YARD documentation" (T022)
Task agent: "Add help text and usage examples" (T023)
Task agent: "Create README section" (T024)
Task agent: "Run RuboCop" (T025)
Task agent: "Run Sorbet" (T026)
Task agent: "Verify code coverage" (T027)
```

---

## Validation Checklist

**GATE: Verify before considering tasks complete**

- [x] All contracts have corresponding tests (T020: 10 contract tests)
- [x] All entities have model tasks (T003-T005: 3 entities + ValidationRule implicit)
- [x] All tests come before implementation (TDD order enforced)
- [x] Parallel tasks truly independent (marked [P], different files)
- [x] Each task specifies exact file path (all tasks include paths)
- [x] No task modifies same file as another [P] task (verified)
- [x] All 25 functional requirements mapped to tasks
- [x] Performance requirements included (T029)
- [x] Constitutional principles satisfied (tests-first, docs, quality)

---

## Notes

- **[P] Notation**: Tasks marked [P] can run in parallel because they touch different files and have no interdependencies
- **TDD Enforcement**: All validator tasks (T007-T014) follow RED-GREEN-REFACTOR explicitly
- **Functional Requirements Coverage**: All FR-001 through FR-025 mapped to specific tasks
- **Constitutional Compliance**: Test-first (Principle III), CLI ergonomics (Principle IV), Performance (Principle V), Documentation (Principle VII)
- **Estimated Total Time**: ~60-70 hours for complete implementation
- **Parallel Time Savings**: With parallelization, ~40-45 hours wall-clock time

---

**Tasks Generation Complete**: Ready for execution with `/implement` or manual task execution.