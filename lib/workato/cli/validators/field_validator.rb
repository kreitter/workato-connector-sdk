# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates field types and definitions (FR-011, FR-023)
      class FieldValidator < BaseValidator
        VALID_FIELD_TYPES = %w[string integer number boolean date datetime timestamp object array].freeze

        def validate
          findings = []

          return findings unless structure.syntax_valid
          return findings unless structure.connector_hash

          findings.concat(validate_field_types)

          findings
        end

        private

        def validate_field_types
          findings = []

          # Check actions
          structure.actions.each do |action_name, action|
            fields = extract_fields(action)
            fields.each do |field|
              next unless field[:type] || field['type']

              field_type = (field[:type] || field['type']).to_s
              next if VALID_FIELD_TYPES.include?(field_type)

              findings << report_finding(
                rule_name: 'invalid_field_type',
                severity: :error,
                message: "Action '#{action_name}' has invalid field type: #{field_type}",
                suggested_fix: "Use one of: #{VALID_FIELD_TYPES.join(', ')}",
                context: {
                  action: action_name,
                  field_name: field[:name] || field['name'],
                  invalid_type: field_type,
                  valid_types: VALID_FIELD_TYPES
                }
              )
            end
          end

          # Check triggers
          structure.triggers.each do |trigger_name, trigger|
            fields = extract_fields(trigger)
            fields.each do |field|
              next unless field[:type] || field['type']

              field_type = (field[:type] || field['type']).to_s
              next if VALID_FIELD_TYPES.include?(field_type)

              findings << report_finding(
                rule_name: 'invalid_field_type',
                severity: :error,
                message: "Trigger '#{trigger_name}' has invalid field type: #{field_type}",
                suggested_fix: "Use one of: #{VALID_FIELD_TYPES.join(', ')}"
              )
            end
          end

          findings
        end

        def extract_fields(component)
          fields = []

          # Try to extract fields from input_fields and output_fields
          %i[input_fields output_fields].each do |field_type|
            field_lambda = component[field_type] || component[field_type.to_s]
            next unless field_lambda.is_a?(Proc)

            begin
              result = field_lambda.call({})
              fields.concat(Array(result)) if result
            rescue StandardError
              # If lambda execution fails, skip it
            end
          end

          fields
        end
      end
    end
  end
end