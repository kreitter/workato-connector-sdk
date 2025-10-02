# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::BaseValidator do
  let(:structure) do
    Workato::Connector::Sdk::Validation::ConnectorStructure.new('{ title: "Test" }').tap(&:parse!)
  end

  describe '#validate' do
    it 'raises NotImplementedError (abstract method)' do
      validator = described_class.new(structure)

      expect { validator.validate }.to raise_error(
        NotImplementedError,
        /Subclasses must implement #validate/
      )
    end
  end

  describe '#report_finding' do
    let(:validator) { described_class.new(structure) }

    it 'creates ValidationFinding with given parameters' do
      finding = validator.send(
        :report_finding,
        rule_name: 'test_rule',
        severity: :error,
        message: 'Test message'
      )

      expect(finding).to be_a(Workato::Connector::Sdk::Validation::Finding)
      expect(finding.rule_name).to eq('test_rule')
      expect(finding.severity).to eq(:error)
      expect(finding.message).to eq('Test message')
    end

    it 'accepts optional parameters' do
      finding = validator.send(
        :report_finding,
        rule_name: 'test_rule',
        severity: :warning,
        message: 'Test message',
        line_number: 42,
        suggested_fix: 'Fix this'
      )

      expect(finding.line_number).to eq(42)
      expect(finding.suggested_fix).to eq('Fix this')
    end

    it 'returns Finding instance' do
      finding = validator.send(
        :report_finding,
        rule_name: 'test',
        severity: :error,
        message: 'test'
      )

      expect(finding).to be_a(Workato::Connector::Sdk::Validation::Finding)
    end
  end

  describe 'protected helpers' do
    let(:validator) { described_class.new(structure) }

    it 'provides access to connector_structure' do
      expect(validator.send(:structure)).to eq(structure)
    end
  end
end