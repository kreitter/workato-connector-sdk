# frozen_string_literal: true

RSpec.describe Workato::Connector::Sdk::Validation::Report do
  let(:error_finding) do
    Workato::Connector::Sdk::Validation::Finding.new(
      rule_name: 'test_error',
      severity: :error,
      message: 'Error message'
    )
  end

  let(:warning_finding) do
    Workato::Connector::Sdk::Validation::Finding.new(
      rule_name: 'test_warning',
      severity: :warning,
      message: 'Warning message'
    )
  end

  let(:info_finding) do
    Workato::Connector::Sdk::Validation::Finding.new(
      rule_name: 'test_info',
      severity: :info,
      message: 'Info message'
    )
  end

  describe '#initialize' do
    it 'requires connector_path and findings' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding]
      )

      expect(report.connector_path).to eq('/path/to/connector.rb')
      expect(report.findings).to eq([error_finding])
    end

    it 'automatically sets validated_at timestamp' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: []
      )

      expect(report.validated_at).to be_a(Time)
      expect(report.validated_at).to be_within(1).of(Time.now)
    end

    it 'calculates status based on findings' do
      report_with_errors = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding, warning_finding]
      )
      expect(report_with_errors.status).to eq(:fail)

      report_with_warnings = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [warning_finding]
      )
      expect(report_with_warnings.status).to eq(:warnings_only)

      report_clean = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: []
      )
      expect(report_clean.status).to eq(:pass)
    end
  end

  describe '#error_count' do
    it 'counts findings with severity :error' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding, error_finding, warning_finding]
      )

      expect(report.error_count).to eq(2)
    end
  end

  describe '#warning_count' do
    it 'counts findings with severity :warning' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding, warning_finding, warning_finding]
      )

      expect(report.warning_count).to eq(2)
    end
  end

  describe '#info_count' do
    it 'counts findings with severity :info' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [info_finding, info_finding, warning_finding]
      )

      expect(report.info_count).to eq(2)
    end
  end

  describe '#pass?' do
    it 'returns true when no errors' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [warning_finding]
      )

      expect(report.pass?).to be true
    end

    it 'returns false when errors present' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding]
      )

      expect(report.pass?).to be false
    end
  end

  describe '#fail?' do
    it 'returns true when errors present' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding]
      )

      expect(report.fail?).to be true
    end

    it 'returns false when no errors' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [warning_finding]
      )

      expect(report.fail?).to be false
    end
  end

  describe '#exit_code' do
    it 'returns 0 for pass (no errors or warnings)' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: []
      )

      expect(report.exit_code).to eq(0)
    end

    it 'returns 1 for fail (errors present)' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding]
      )

      expect(report.exit_code).to eq(1)
    end

    it 'returns 2 for warnings_only (warnings but no errors)' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [warning_finding]
      )

      expect(report.exit_code).to eq(2)
    end
  end

  describe '#to_json' do
    it 'generates valid JSON with connector_path, validated_at, status, findings' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding],
        duration_ms: 123
      )

      json_output = JSON.parse(report.to_json)

      expect(json_output['connector_path']).to eq('/path/to/connector.rb')
      expect(json_output['validated_at']).to be_a(String)
      expect(json_output['status']).to eq('fail')
      expect(json_output['duration_ms']).to eq(123)
      expect(json_output['findings']).to be_an(Array)
    end

    it 'includes summary with error_count, warning_count, info_count' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding, warning_finding, info_finding],
        duration_ms: 123
      )

      json_output = JSON.parse(report.to_json)

      expect(json_output['summary']).to eq({
        'error_count' => 1,
        'warning_count' => 1,
        'info_count' => 1
      })
    end
  end

  describe '#to_human' do
    it 'generates color-coded output with findings' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding],
        duration_ms: 123
      )

      output = report.to_human

      expect(output).to include('ERROR')
      expect(output).to include('Error message')
    end

    it 'shows summary line with counts' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [error_finding, warning_finding],
        duration_ms: 123
      )

      output = report.to_human

      expect(output).to match(/\d+ error/)
      expect(output).to match(/\d+ warning/)
    end

    it 'shows duration in seconds' do
      report = described_class.new(
        connector_path: '/path/to/connector.rb',
        findings: [],
        duration_ms: 1234
      )

      output = report.to_human

      expect(output).to match(/Duration: \d+\.\d+s/)
    end
  end
end