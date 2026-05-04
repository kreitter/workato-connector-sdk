# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates anti-patterns (FR-012, FR-013, FR-014, FR-022, FR-024, FR-025)
      class AntiPatternValidator < BaseValidator
        # Patterns that might indicate hardcoded credentials
        # Note: These patterns look for literal tokens/keys, not interpolated connection values
        CREDENTIAL_PATTERNS = [
          /['"]Bearer\s+[A-Za-z0-9_\-]{30,}['"]/,  # Long Bearer tokens
          /headers\([^)]*['"]Authorization['"]\s*=>\s*['"][^#\{][^'"]{20,}['"]/,  # Literal auth headers (not interpolated)
          /\bapi[_-]?key:\s*['"][A-Za-z0-9_\-]{20,}['"]/i,  # api_key: "literal_key"
          /\btoken:\s*['"][A-Za-z0-9_\-]{20,}['"]/i  # token: "literal_token"
        ].freeze

        def validate
          findings = []

          return findings unless structure.syntax_valid
          return findings unless structure.connector_hash

          findings.concat(validate_hardcoded_credentials)
          findings.concat(validate_methods_block)
          findings.concat(validate_action_trigger_names)

          findings
        end

        private

        def validate_hardcoded_credentials
          findings = []

          CREDENTIAL_PATTERNS.each do |pattern|
            next unless structure.source_code.match?(pattern)

            findings << report_finding(
              rule_name: 'hardcoded_credentials',
              severity: :error,
              message: 'Possible hardcoded credentials detected',
              suggested_fix: 'Use connection parameters instead of hardcoding credentials'
            )
            break # Only report once
          end

          findings
        end

        def validate_methods_block
          findings = []

          structure.methods.each do |name, value|
            next if value.is_a?(Proc)

            findings << report_finding(
              rule_name: 'methods_non_lambda',
              severity: :error,
              message: "Methods block contains non-lambda value: #{name}",
              suggested_fix: 'Methods block should only contain lambda definitions'
            )
          end

          findings
        end

        def validate_action_trigger_names
          findings = []

          # Check action names
          structure.actions.each_key do |name|
            next if valid_symbol_name?(name)

            findings << report_finding(
              rule_name: 'invalid_action_name',
              severity: :error,
              message: "Invalid action name: #{name} (must be valid Ruby symbol)",
              suggested_fix: 'Use underscores instead of spaces, avoid special characters'
            )
          end

          # Check trigger names
          structure.triggers.each_key do |name|
            next if valid_symbol_name?(name)

            findings << report_finding(
              rule_name: 'invalid_trigger_name',
              severity: :error,
              message: "Invalid trigger name: #{name} (must be valid Ruby symbol)",
              suggested_fix: 'Use underscores instead of spaces, avoid special characters'
            )
          end

          findings
        end

        def valid_symbol_name?(name)
          # Valid Ruby symbol: starts with letter or underscore, contains letters, digits, underscores
          name.to_s.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
        end
      end
    end
  end
end