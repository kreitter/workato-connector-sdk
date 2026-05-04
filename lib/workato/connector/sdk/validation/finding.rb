# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Validation
        ##
        # Represents a specific issue discovered during connector validation.
        #
        # A Finding contains all information about a validation rule violation,
        # including severity level, location in source code, error message,
        # and optional suggested fix.
        #
        # @attr_reader [String] rule_name Unique identifier for the validation rule
        # @attr_reader [Symbol] severity One of :error, :warning, or :info
        # @attr_reader [String] message Human-readable description of the issue
        # @attr_reader [Integer, nil] line_number Line number in source code where issue occurs
        # @attr_reader [Integer, nil] column_number Column number in source code
        # @attr_reader [String, nil] suggested_fix Recommended fix for the issue
        # @attr_reader [Hash] context Additional metadata about the finding
        #
        # @example Create an error finding
        #   finding = Finding.new(
        #     rule_name: 'missing_section',
        #     severity: :error,
        #     message: 'Missing required section: test',
        #     line_number: 42,
        #     suggested_fix: 'Add test: lambda block'
        #   )
        #
        # @example Check finding severity
        #   finding.error? #=> true
        #   finding.warning? #=> false
        class Finding
          VALID_SEVERITIES = %i[error warning info].freeze

          attr_reader :rule_name, :severity, :message, :line_number, :column_number,
                      :suggested_fix, :context

          ##
          # Creates a new validation finding.
          #
          # @param rule_name [String] Unique identifier for the validation rule
          # @param severity [Symbol] Must be one of :error, :warning, or :info
          # @param message [String] Human-readable description of the issue
          # @param line_number [Integer, nil] Line number where issue occurs
          # @param column_number [Integer, nil] Column number where issue occurs
          # @param suggested_fix [String, nil] Recommended fix for the issue
          # @param context [Hash] Additional metadata about the finding
          #
          # @raise [Workato::Connector::Sdk::ArgumentError] if severity is invalid
          def initialize(rule_name:, severity:, message:, line_number: nil,
                        column_number: nil, suggested_fix: nil, context: {})
            validate_severity!(severity)

            @rule_name = rule_name
            @severity = severity
            @message = message
            @line_number = line_number
            @column_number = column_number
            @suggested_fix = suggested_fix
            @context = context
          end

          ##
          # Checks if this finding is an error.
          #
          # @return [Boolean] true if severity is :error
          def error?
            severity == :error
          end

          ##
          # Checks if this finding is a warning.
          #
          # @return [Boolean] true if severity is :warning
          def warning?
            severity == :warning
          end

          ##
          # Checks if this finding is informational.
          #
          # @return [Boolean] true if severity is :info
          def info?
            severity == :info
          end

          ##
          # Formats the location of this finding as a human-readable string.
          #
          # @return [String] Location string like "line 42:10", "line 42", or "file-level"
          def location_string
            if line_number && column_number
              "line #{line_number}:#{column_number}"
            elsif line_number
              "line #{line_number}"
            else
              'file-level'
            end
          end

          def to_s
            "#{severity} (#{location_string}): #{message}"
          end

          private

          def validate_severity!(severity)
            return if VALID_SEVERITIES.include?(severity)

            raise ArgumentError, "severity must be :error, :warning, or :info, got: #{severity.inspect}"
          end
        end
      end
    end
  end
end