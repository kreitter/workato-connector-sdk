# frozen_string_literal: true

RSpec.describe Workato::Connector::Sdk::Validation::Finding do
  describe '#initialize' do
    it 'requires rule_name, severity, message' do
      finding = described_class.new(
        rule_name: 'test_rule',
        severity: :error,
        message: 'Test message'
      )

      expect(finding.rule_name).to eq('test_rule')
      expect(finding.severity).to eq(:error)
      expect(finding.message).to eq('Test message')
    end

    it 'accepts optional line_number, column_number, suggested_fix, context' do
      finding = described_class.new(
        rule_name: 'test_rule',
        severity: :warning,
        message: 'Test message',
        line_number: 42,
        column_number: 10,
        suggested_fix: 'Fix this',
        context: { key: 'value' }
      )

      expect(finding.line_number).to eq(42)
      expect(finding.column_number).to eq(10)
      expect(finding.suggested_fix).to eq('Fix this')
      expect(finding.context).to eq({ key: 'value' })
    end

    it 'validates severity is :error, :warning, or :info' do
      expect do
        described_class.new(
          rule_name: 'test',
          severity: :invalid,
          message: 'test'
        )
      end.to raise_error(Workato::Connector::Sdk::ArgumentError, /severity must be :error, :warning, or :info/)
    end
  end

  describe '#error?' do
    it 'returns true when severity is :error' do
      finding = described_class.new(rule_name: 'test', severity: :error, message: 'test')
      expect(finding.error?).to be true
    end

    it 'returns false when severity is not :error' do
      finding = described_class.new(rule_name: 'test', severity: :warning, message: 'test')
      expect(finding.error?).to be false
    end
  end

  describe '#warning?' do
    it 'returns true when severity is :warning' do
      finding = described_class.new(rule_name: 'test', severity: :warning, message: 'test')
      expect(finding.warning?).to be true
    end

    it 'returns false when severity is not :warning' do
      finding = described_class.new(rule_name: 'test', severity: :error, message: 'test')
      expect(finding.warning?).to be false
    end
  end

  describe '#info?' do
    it 'returns true when severity is :info' do
      finding = described_class.new(rule_name: 'test', severity: :info, message: 'test')
      expect(finding.info?).to be true
    end

    it 'returns false when severity is not :info' do
      finding = described_class.new(rule_name: 'test', severity: :error, message: 'test')
      expect(finding.info?).to be false
    end
  end

  describe '#location_string' do
    it 'formats "line X" when only line_number present' do
      finding = described_class.new(
        rule_name: 'test',
        severity: :error,
        message: 'test',
        line_number: 42
      )
      expect(finding.location_string).to eq('line 42')
    end

    it 'formats "line X:Y" when both line and column present' do
      finding = described_class.new(
        rule_name: 'test',
        severity: :error,
        message: 'test',
        line_number: 42,
        column_number: 10
      )
      expect(finding.location_string).to eq('line 42:10')
    end

    it 'returns "file-level" when no line_number' do
      finding = described_class.new(
        rule_name: 'test',
        severity: :error,
        message: 'test'
      )
      expect(finding.location_string).to eq('file-level')
    end
  end

  describe '#to_s' do
    it 'formats finding for display with severity, location, message' do
      finding = described_class.new(
        rule_name: 'test_rule',
        severity: :error,
        message: 'Something went wrong',
        line_number: 42
      )
      result = finding.to_s
      expect(result).to include('error')
      expect(result).to include('line 42')
      expect(result).to include('Something went wrong')
    end
  end
end