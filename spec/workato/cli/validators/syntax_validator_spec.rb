# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::SyntaxValidator do
  let(:validator) { described_class.new(structure) }

  context 'with valid Ruby syntax' do
    let(:structure) do
      code = '{ title: "Test", connection: {}, test: -> {} }'
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with invalid Ruby syntax' do
    let(:structure) do
      code = "{ title: 'Test', connection: {" # unclosed brace
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding with severity :error' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes syntax error message' do
      findings = validator.validate
      expect(findings.first.message).to include('syntax')
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).not_to be_nil
    end
  end

  context 'with empty file' do
    let(:structure) do
      code = ''
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for empty connector' do
      findings = validator.validate
      expect(findings).not_to be_empty
    end
  end
end