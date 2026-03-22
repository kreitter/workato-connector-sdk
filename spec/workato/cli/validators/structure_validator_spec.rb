# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::StructureValidator do
  let(:validator) { described_class.new(structure) }

  context 'with all required sections present' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test Connector',
          connection: {
            fields: [{ name: 'api_key' }]
          },
          test: lambda { |connection| true }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with minimal valid connector' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Minimal',
          connection: {},
          test: lambda {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with missing title section' do
    let(:structure) do
      code = <<~RUBY
        {
          connection: {},
          test: lambda {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for missing title' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('required_section_title')
    end

    it 'has error severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('title:')
    end
  end

  context 'with missing connection section' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          test: lambda {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for missing connection' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('required_section_connection')
    end

    it 'has error severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('connection:')
    end
  end

  context 'with missing test section' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for missing test' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('required_section_test')
    end

    it 'has error severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('test:')
    end
  end

  context 'with all sections missing' do
    let(:structure) do
      code = <<~RUBY
        {
          actions: {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for all missing sections' do
      findings = validator.validate
      expect(findings.size).to eq(3)
      rule_names = findings.map(&:rule_name)
      expect(rule_names).to include('required_section_title')
      expect(rule_names).to include('required_section_connection')
      expect(rule_names).to include('required_section_test')
    end

    it 'all findings are errors' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.severity).to eq(:error)
      end
    end
  end

  context 'with syntax error' do
    let(:structure) do
      code = <<~RUBY
        { title: 'Test', connection: {, test: lambda {} }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array (syntax errors handled separately)' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with additional optional sections' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Full Connector',
          connection: {},
          test: lambda {},
          actions: {
            test_action: { execute: lambda {} }
          },
          triggers: {
            test_trigger: { poll: lambda {} }
          },
          object_definitions: {},
          pick_lists: {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end
end
