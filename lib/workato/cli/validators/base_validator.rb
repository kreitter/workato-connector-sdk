# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Base class for all validation rules
      class BaseValidator
        def initialize(structure)
          @structure = structure
        end

        def validate
          raise NotImplementedError, 'Subclasses must implement #validate'
        end

        protected

        attr_reader :structure

        def report_finding(rule_name:, severity:, message:, line_number: nil,
                          column_number: nil, suggested_fix: nil, context: {})
          Workato::Connector::Sdk::Validation::Finding.new(
            rule_name: rule_name,
            severity: severity,
            message: message,
            line_number: line_number,
            column_number: column_number,
            suggested_fix: suggested_fix,
            context: context
          )
        end
      end
    end
  end
end