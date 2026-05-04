# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates deprecated DSL patterns (FR-010)
      class DeprecationValidator < BaseValidator
        DEPRECATED_PATTERNS = {
          'after_error_response' => {
            replacement: 'error_handler',
            message: 'after_error_response is deprecated. Use error_handler instead.',
            severity: :warning
          },
          'request_format_www_form_urlencoded' => {
            replacement: 'request_format_www_form_urlencoded',
            message: 'Consider using modern request format methods',
            severity: :info
          }
        }.freeze

        def validate
          findings = []

          return findings unless structure.syntax_valid

          DEPRECATED_PATTERNS.each do |pattern, info|
            next unless structure.source_code.include?(pattern)

            findings << report_finding(
              rule_name: 'deprecated_dsl_method',
              severity: info[:severity],
              message: "Use of deprecated method #{pattern}",
              suggested_fix: info[:message],
              context: {
                deprecated_method: pattern,
                replacement: info[:replacement]
              }
            )
          end

          findings
        end
      end
    end
  end
end