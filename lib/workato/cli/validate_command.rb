# frozen_string_literal: true

require_relative '../connector/sdk/validation/finding'
require_relative '../connector/sdk/validation/report'
require_relative '../connector/sdk/validation/connector_structure'
require_relative 'validators/base_validator'
require_relative 'validators/syntax_validator'
require_relative 'validators/structure_validator'
require_relative 'validators/connection_validator'
require_relative 'validators/reference_validator'
require_relative 'validators/signature_validator'
require_relative 'validators/field_validator'
require_relative 'validators/deprecation_validator'
require_relative 'validators/anti_pattern_validator'

module Workato
  module CLI
    # Validates connector code for structural errors and DSL violations
    class ValidateCommand
      def initialize(options = {})
        @options = options
      end

      def call
        start_time = Time.now
        connector_path = @options[:connector] || 'connector.rb'

        # 1. Check file exists (FR-001)
        unless File.exist?(connector_path)
          handle_file_not_found(connector_path)
          return 1
        end

        puts "Validating #{connector_path}...\n\n" unless @options[:output]

        # 2. Read connector file
        begin
          source_code = File.read(connector_path)
        rescue Errno::EACCES => e
          handle_permission_error(connector_path, e)
          return 1
        end

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

        # 7. Return exit code (FR-018)
        report.exit_code
      rescue StandardError => e
        handle_unexpected_error(e)
        1
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

        # Run validators and collect findings
        findings = validators.flat_map do |validator_class|
          validator_class.new(structure).validate
        end

        # Sort findings: errors first, then by line number
        findings.sort_by { |f| [f.severity == :error ? 0 : (f.severity == :warning ? 1 : 2), f.line_number || 0] }
      end

      def output_report(report)
        if @options[:output]
          # JSON output (FR-016)
          File.write(@options[:output], report.to_json)
          puts "Validation report written to #{@options[:output]}"
        else
          # Human-readable output (FR-017)
          puts report.to_human(verbose: @options[:verbose])
        end
      end

      def handle_file_not_found(path)
        puts "ERROR: Connector file not found at '#{path}'\n\n"
        puts "Suggestion: Check the file path, or run 'workato new' to create a new connector."
      end

      def handle_permission_error(path, _error)
        puts "ERROR: Permission denied reading '#{path}'\n\n"
        puts 'Suggestion: Check file permissions and ensure you have read access.'
      end

      def handle_unexpected_error(error)
        puts "ERROR: Unexpected error during validation: #{error.message}"
        puts error.backtrace.join("\n") if ENV['DEBUG']
      end
    end
  end
end