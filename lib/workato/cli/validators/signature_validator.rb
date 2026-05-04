# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates lambda signatures (FR-007, FR-008, FR-009, FR-021)
      class SignatureValidator < BaseValidator
        def validate
          findings = []

          return findings unless structure.syntax_valid
          return findings unless structure.connector_hash

          findings.concat(validate_action_signatures)
          findings.concat(validate_trigger_signatures)

          findings
        end

        private

        def validate_action_signatures
          findings = []

          structure.actions.each do |name, action|
            next unless action[:execute].is_a?(Proc)

            param_count = action[:execute].arity

            # Execute should have at least 2 params (connection, input)
            # Full signature: (connection, input, input_schema, output_schema, closure)
            if param_count < 2 && param_count != -1 # -1 means variable args
              findings << report_finding(
                rule_name: 'invalid_execute_signature',
                severity: :error,
                message: "Action '#{name}' execute must accept at least (connection, input)",
                suggested_fix: 'Update execute: lambda { |connection, input, ...| }'
              )
            end
          end

          findings
        end

        def validate_trigger_signatures
          findings = []

          structure.triggers.each do |name, trigger|
            # Check poll signature
            if trigger[:poll].is_a?(Proc)
              param_count = trigger[:poll].arity

              if param_count < 3 && param_count != -1
                findings << report_finding(
                  rule_name: 'invalid_poll_signature',
                  severity: :error,
                  message: "Trigger '#{name}' poll must accept at least (connection, input, closure)",
                  suggested_fix: 'Update poll: lambda { |connection, input, closure| }'
                )
              end
            end

            # Check webhook signatures
            if trigger[:type] == 'webhook' || trigger['type'] == 'webhook'
              unless trigger[:webhook_subscribe] || trigger['webhook_subscribe']
                findings << report_finding(
                  rule_name: 'missing_webhook_subscribe',
                  severity: :error,
                  message: "Webhook trigger '#{name}' missing webhook_subscribe",
                  suggested_fix: 'Add webhook_subscribe: lambda { |webhook_url, connection, input, recipe_id| }'
                )
              end

              unless trigger[:webhook_notification] || trigger['webhook_notification']
                findings << report_finding(
                  rule_name: 'missing_webhook_notification',
                  severity: :error,
                  message: "Webhook trigger '#{name}' missing webhook_notification",
                  suggested_fix: 'Add webhook_notification: lambda { |input, payload| }'
                )
              end
            end
          end

          findings
        end
      end
    end
  end
end