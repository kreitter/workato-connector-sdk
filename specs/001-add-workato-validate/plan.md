
# Implementation Plan: Workato Validate Command

**Branch**: `001-add-workato-validate` | **Date**: 2025-01-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/Users/dave/Documents/GitHub/workato-connector-sdk/specs/001-add-workato-validate/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
The `workato validate` command is a new CLI feature that enables connector developers to validate their connector.rb files for structural errors, missing required sections, invalid syntax, and DSL convention violations before deployment. The validation system will provide actionable error messages with line numbers, support multiple output formats (human-readable with colors and JSON for CI/CD), and complete validation within 10 seconds for connectors up to 5000 lines. The command will return appropriate exit codes (0 for pass, 1 for errors, 2 for warnings only) and support flags for verbose output and custom file paths.

## Technical Context
**Language/Version**: Ruby >= 2.7.6 (per gemspec requirement)
**Primary Dependencies**: Thor (CLI framework ~> 1.0), Ruby parser/AST libraries (Ripper or Parser gem for syntax validation), Sorbet runtime (~> 0.5 for type safety), ActiveSupport (>= 5.2, < 7.1)
**Storage**: N/A (validation is stateless, reads connector.rb files)
**Testing**: RSpec (existing test framework in project), VCR for HTTP mocking, WebMock
**Target Platform**: Cross-platform CLI (macOS, Linux, Windows via Ruby)
**Project Type**: Single (Ruby gem with CLI interface)
**Performance Goals**: Complete validation within 10 seconds for connectors up to 5000 lines (FR-019)
**Constraints**: Exit code 0 for pass, 1 for errors, 2 for warnings only (FR-018); must integrate with existing Thor-based CLI structure
**Scale/Scope**: Validate individual connector.rb files (typically 500-5000 lines); support 25 validation rules (FR-001 through FR-025)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applies | Status | Notes |
|-----------|---------|--------|-------|
| I. Backward Compatibility | ✅ Yes | ✅ PASS | New CLI command, no breaking changes to existing API |
| II. DSL Parity with Platform | ✅ Yes | ✅ PASS | Validates DSL usage, ensures SDK accurately reflects platform constraints |
| III. Test-First Development | ✅ Yes | ✅ PASS | Will write RSpec tests before implementation; validate command tests added |
| IV. CLI Ergonomics and Consistency | ✅ Yes | ✅ PASS | Follows `workato <command> [options]` pattern; supports --help, --verbose, --output, --connector flags |
| V. Performance Boundaries | ✅ Yes | ✅ PASS | Target <10s for 5000 line files; command startup <2s (Thor overhead minimal) |
| VI. Security by Default | ⚠️ Partial | ✅ PASS | Does not handle credentials directly; reads connector code only |
| VII. Documentation as Code | ✅ Yes | ✅ PASS | Will include YARD docs, --help text, examples, and integration test demonstrating usage |

**Quality Standards**:
- **Ruby Style**: Will follow existing .rubocop.yml rules
- **Type Safety**: Sorbet type annotations for public methods in validation logic
- **Complexity**: Validation rules encapsulated as separate classes; each rule <15 cyclomatic complexity
- **Testing**: Unit tests for each validation rule + integration tests for CLI command
- **Dependencies**: Parser/Ripper (stdlib) for AST analysis; no new external gems required beyond stdlib

**Overall Gate Status**: ✅ PASS - All constitutional principles satisfied

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/workato/
├── cli/
│   ├── main.rb                       # Thor CLI main class (register validate command)
│   ├── validate_command.rb           # NEW: ValidateCommand implementation
│   └── validators/                   # NEW: Validation logic modules
│       ├── base_validator.rb         # Base class for all validators
│       ├── syntax_validator.rb       # Ruby syntax validation (FR-004)
│       ├── structure_validator.rb    # Required sections (FR-002)
│       ├── connection_validator.rb   # Connection/auth validation (FR-003)
│       ├── reference_validator.rb    # object_definitions, pick_lists refs (FR-005, FR-006)
│       ├── signature_validator.rb    # Block signatures (FR-007, FR-008, FR-009, FR-021)
│       ├── field_validator.rb        # Field types and definitions (FR-011, FR-023)
│       ├── deprecation_validator.rb  # Deprecated DSL patterns (FR-010)
│       └── anti_pattern_validator.rb # Security and best practices (FR-012, FR-013, FR-014, FR-022, FR-024, FR-025)
├── connector/
│   └── sdk/
│       └── validation/               # NEW: Validation domain models
│           ├── report.rb             # ValidationReport entity
│           ├── finding.rb            # ValidationFinding entity
│           ├── rule.rb               # ValidationRule entity
│           └── connector_structure.rb # ConnectorStructure entity

spec/workato/
├── cli/
│   └── validate_command_spec.rb      # NEW: Integration tests for validate command
└── connector/sdk/validation/          # NEW: Unit tests for validators
    ├── syntax_validator_spec.rb
    ├── structure_validator_spec.rb
    ├── connection_validator_spec.rb
    ├── reference_validator_spec.rb
    ├── signature_validator_spec.rb
    ├── field_validator_spec.rb
    ├── deprecation_validator_spec.rb
    └── anti_pattern_validator_spec.rb

spec/fixtures/
└── validation/                       # NEW: Test fixtures for validate command
    ├── valid_connector.rb
    ├── invalid_syntax_connector.rb
    ├── missing_sections_connector.rb
    └── deprecated_patterns_connector.rb
```

**Structure Decision**: Single Ruby gem project structure. New validation command integrates into existing Thor-based CLI at `lib/workato/cli/`. Validators are modular, following single-responsibility principle. Domain models live under `lib/workato/connector/sdk/validation/`. Tests mirror source structure under `spec/`.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
1. Load `.specify/templates/tasks-template.md` as base template
2. Generate tasks from Phase 1 design artifacts:
   - **data-model.md** → Entity creation tasks for ValidationReport, ValidationFinding, ValidationRule, ConnectorStructure
   - **contracts/cli-interface.md** → CLI integration test tasks for each contract test case (10 test scenarios)
   - **quickstart.md** → Acceptance test tasks for 7 user scenarios + 5 edge cases
   - **research.md** → Implementation tasks for 9 validator classes based on research decisions

3. **Task Categories**:
   - **Setup Tasks** (1-2): Test infrastructure, fixtures directory structure
   - **Entity Tasks** (3-6): Create domain models [P - can run in parallel]
   - **Validator Tasks** (7-15): Create validator classes with unit tests [P - independent]
   - **CLI Tasks** (16-18): Integrate into Thor CLI, implement command
   - **Integration Tasks** (19-21): End-to-end CLI tests
   - **Acceptance Tasks** (22-28): Implement quickstart scenarios
   - **Documentation Tasks** (29-30): YARD docs, help text, examples

**Ordering Strategy**:
- **TDD Order**: Write tests BEFORE implementation for each component
  - Example: `syntax_validator_spec.rb` → `syntax_validator.rb`
- **Dependency Order**:
  1. Entities first (no dependencies)
  2. Base validator class (entities depend on it)
  3. Concrete validators (depend on base + entities) [P]
  4. CLI command (depends on validators)
  5. Integration tests (depend on complete CLI)
- **Parallel Execution**: Mark [P] for tasks with no interdependencies
  - All entity creation tasks [P]
  - All validator implementation tasks [P]
  - All unit test tasks [P]

**Task Breakdown by Functional Requirements**:
- FR-001, FR-002 → StructureValidator tasks
- FR-003 → ConnectionValidator tasks
- FR-004 → SyntaxValidator tasks
- FR-005, FR-006 → ReferenceValidator tasks
- FR-007, FR-008, FR-009, FR-021 → SignatureValidator tasks
- FR-010 → DeprecationValidator tasks
- FR-011, FR-023 → FieldValidator tasks
- FR-012, FR-013, FR-014, FR-022, FR-024, FR-025 → AntiPatternValidator tasks
- FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 → ValidateCommand CLI tasks

**Estimated Output**: ~35-40 numbered, dependency-ordered tasks in tasks.md

**Example Task Structure**:
```
## Task 7: Create SyntaxValidator with tests [P]
**Type**: Implementation
**Functional Requirement**: FR-004
**Dependencies**: Task 3 (ValidationFinding), Task 6 (BaseValidator)
**Estimated Time**: 2 hours

### TDD Steps:
1. Create spec/workato/connector/sdk/validation/syntax_validator_spec.rb
   - Test: valid Ruby syntax → no findings
   - Test: invalid syntax → finding with line number and error message
   - Test: empty file → finding
2. Run specs (RED - tests fail)
3. Create lib/workato/cli/validators/syntax_validator.rb
   - Use Ripper.sexp for parsing
   - Extract line numbers from error messages
   - Return ValidationFinding array
4. Run specs (GREEN - tests pass)
5. Refactor if needed

### Success Criteria:
- [ ] Unit tests pass
- [ ] Rubocop passes
- [ ] Sorbet type check passes
- [ ] Coverage ≥90%
```

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
  - Created research.md with 10 technical decisions
  - All unknowns resolved (Ruby AST parsing, validation architecture, performance optimization)
- [x] Phase 1: Design complete (/plan command)
  - Created data-model.md with 4 entities + relationships
  - Created contracts/cli-interface.md with CLI specification
  - Created quickstart.md with 7 acceptance scenarios + 5 edge cases
  - Updated CLAUDE.md via update-agent-context.sh
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
  - Defined task generation strategy from design artifacts
  - Mapped 35-40 tasks across 6 categories
  - Specified TDD order + parallel execution strategy
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
  - All 7 constitutional principles satisfied
  - Test-first development planned
  - CLI ergonomics follow existing patterns
  - No backward compatibility issues
- [x] Post-Design Constitution Check: PASS
  - Design maintains constitutional compliance
  - No new complexity violations introduced
  - Quality standards upheld (Sorbet, RSpec, <15 complexity)
- [x] All NEEDS CLARIFICATION resolved
  - Technical Context fully specified (Ruby 2.7.6+, Thor, Ripper)
  - All research questions answered
- [x] Complexity deviations documented
  - No deviations required

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
