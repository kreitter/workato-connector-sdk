# frozen_string_literal: true

require 'json'
require 'time'

module Workato
  module Connector
    module Sdk
      module Validation
        # Represents the complete validation outcome for a connector file
        class Report
          attr_reader :connector_path, :validated_at, :findings, :status, :duration_ms

          def initialize(connector_path:, findings:, duration_ms: 0)
            @connector_path = connector_path
            @findings = findings
            @duration_ms = duration_ms
            @validated_at = Time.now
            @status = calculate_status
          end

          def error_count
            findings.count(&:error?)
          end

          def warning_count
            findings.count(&:warning?)
          end

          def info_count
            findings.count(&:info?)
          end

          def pass?
            error_count.zero?
          end

          def fail?
            !pass?
          end

          def exit_code
            if fail?
              1
            elsif warning_count.positive?
              2
            else
              0
            end
          end

          def to_json(*_args)
            JSON.generate({
              connector_path: connector_path,
              validated_at: validated_at.iso8601,
              status: status.to_s,
              duration_ms: duration_ms,
              summary: {
                error_count: error_count,
                warning_count: warning_count,
                info_count: info_count
              },
              findings: findings.map { |f| finding_to_hash(f) }
            })
          end

          def to_human(verbose: false)
            lines = []

            if findings.empty? && !verbose
              lines << "✓ Connector validation passed\n"
            else
              findings.each do |finding|
                lines << format_finding(finding)
              end

              if verbose && findings.empty?
                lines << "✓ All validation checks passed"
              end
            end

            lines << separator if findings.any?
            lines << summary_line
            lines << "Duration: #{format_duration}"

            lines.join("\n")
          end

          private

          def calculate_status
            if error_count.positive?
              :fail
            elsif warning_count.positive?
              :warnings_only
            else
              :pass
            end
          end

          def finding_to_hash(finding)
            {
              rule_name: finding.rule_name,
              severity: finding.severity.to_s,
              message: finding.message,
              line_number: finding.line_number,
              column_number: finding.column_number,
              suggested_fix: finding.suggested_fix,
              context: finding.context
            }
          end

          def format_finding(finding)
            icon = case finding.severity
                   when :error then '❌ ERROR'
                   when :warning then '⚠️  WARNING'
                   when :info then 'ℹ️  INFO'
                   end

            line = "#{icon} (#{finding.location_string}): #{finding.message}"
            line += "\n   → #{finding.suggested_fix}" if finding.suggested_fix
            line
          end

          def separator
            '━' * 60
          end

          def summary_line
            if fail?
              parts = []
              parts << "#{error_count} error#{'s' unless error_count == 1}" if error_count.positive?
              parts << "#{warning_count} warning#{'s' unless warning_count == 1}" if warning_count.positive?
              "Validation failed: #{parts.join(', ')}"
            elsif status == :warnings_only
              "Validation passed with warnings: #{warning_count} warning#{'s' unless warning_count == 1}"
            else
              '✓ Connector validation passed'
            end
          end

          def format_duration
            "#{(duration_ms / 1000.0).round(3)}s"
          end
        end
      end
    end
  end
end