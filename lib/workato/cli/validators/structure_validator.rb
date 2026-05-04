# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates required sections (FR-001, FR-002)
      class StructureValidator < BaseValidator
        REQUIRED_SECTIONS = %i[title connection test].freeze

        def validate
          findings = []

          return findings unless structure.syntax_valid

          REQUIRED_SECTIONS.each do |section|
            next if structure.connector_hash&.key?(section)

            findings << report_finding(
              rule_name: "required_section_#{section}",
              severity: :error,
              message: "Missing required section: #{section}",
              line_number: structure.section_line_number(:program) || 1,
              suggested_fix: suggested_fix_for(section)
            )
          end

          findings
        end

        private

        def suggested_fix_for(section)
          case section
          when :title
            "Add title: 'Your Connector Name' to connector definition"
          when :connection
            'Add connection: { fields: [...], authorization: {...} } to connector definition'
          when :test
            'Add test: lambda { |connection| ... } to connector definition'
          end
        end
      end
    end
  end
end