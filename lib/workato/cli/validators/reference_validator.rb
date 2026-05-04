# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates object_definitions and pick_lists references (FR-005, FR-006)
      class ReferenceValidator < BaseValidator
        def validate
          findings = []

          return findings unless structure.syntax_valid
          return findings unless structure.connector_hash

          findings.concat(validate_object_definition_references)
          findings.concat(validate_pick_list_references)

          findings
        end

        private

        def validate_object_definition_references
          findings = []
          defined = structure.defined_object_definitions

          # Check references in actions
          structure.actions.each do |action_name, action|
            refs = extract_object_definition_refs(action)
            refs.each do |ref|
              next if defined.include?(ref)

              findings << report_finding(
                rule_name: 'undefined_object_definition',
                severity: :error,
                message: "Action '#{action_name}' references undefined object_definition: #{ref}",
                suggested_fix: "Define object_definitions: { #{ref}: { ... } } in connector"
              )
            end
          end

          # Check references in triggers
          structure.triggers.each do |trigger_name, trigger|
            refs = extract_object_definition_refs(trigger)
            refs.each do |ref|
              next if defined.include?(ref)

              findings << report_finding(
                rule_name: 'undefined_object_definition',
                severity: :error,
                message: "Trigger '#{trigger_name}' references undefined object_definition: #{ref}",
                suggested_fix: "Define object_definitions: { #{ref}: { ... } } in connector"
              )
            end
          end

          findings
        end

        def validate_pick_list_references
          findings = []
          defined = structure.defined_pick_lists

          # Check references in actions and triggers
          (structure.actions.merge(structure.triggers)).each do |name, component|
            refs = extract_pick_list_refs(component)
            refs.each do |ref|
              next if defined.include?(ref)

              findings << report_finding(
                rule_name: 'undefined_pick_list',
                severity: :error,
                message: "Component '#{name}' references undefined pick_list: #{ref}",
                suggested_fix: "Define pick_lists: { #{ref}: -> { [...] } } in connector"
              )
            end
          end

          findings
        end

        def extract_object_definition_refs(component)
          refs = []

          # Look for object_definitions[:symbol] patterns in the component
          # This is a simplified extraction - real implementation would parse AST
          component_str = component.to_s
          component_str.scan(/object_definitions\[:(\w+)\]/).each do |match|
            refs << match[0].to_sym
          end

          refs
        end

        def extract_pick_list_refs(component)
          refs = []

          # Look for pick_list: 'name' patterns
          component_str = component.to_s
          component_str.scan(/pick_list:\s*['"](\w+)['"]/).each do |match|
            refs << match[0].to_sym
          end

          refs
        end
      end
    end
  end
end