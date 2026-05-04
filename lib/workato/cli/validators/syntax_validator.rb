# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates Ruby syntax (FR-004)
      class SyntaxValidator < BaseValidator
        def validate
          findings = []

          if structure.source_code.strip.empty?
            findings << report_finding(
              rule_name: 'empty_connector',
              severity: :error,
              message: 'Connector file is empty',
              suggested_fix: 'Add connector definition hash'
            )
          elsif !structure.syntax_valid
            structure.parse_errors.each do |error|
              findings << report_finding(
                rule_name: 'syntax_error',
                severity: :error,
                message: "Ruby #{error}",
                suggested_fix: 'Fix the syntax error at the indicated line'
              )
            end
          end

          findings
        end
      end
    end
  end
end