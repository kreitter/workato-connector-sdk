# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::FieldValidator do
  let(:validator) { described_class.new(structure) }

  context 'with valid field types in action' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              input_fields: lambda { |connection|
                [
                  { name: 'text_field', type: 'string' },
                  { name: 'number_field', type: 'integer' },
                  { name: 'decimal_field', type: 'number' },
                  { name: 'flag_field', type: 'boolean' },
                  { name: 'date_field', type: 'date' },
                  { name: 'datetime_field', type: 'datetime' },
                  { name: 'timestamp_field', type: 'timestamp' },
                  { name: 'object_field', type: 'object' },
                  { name: 'array_field', type: 'array' }
                ]
              },
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with valid field types in trigger' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              input_fields: lambda { |connection|
                [{ name: 'since', type: 'datetime' }]
              },
              output_fields: lambda { |connection|
                [{ name: 'id', type: 'string' }]
              },
              poll: lambda { |connection, input, closure| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with invalid field type in action' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              input_fields: lambda { |connection|
                [{ name: 'invalid_field', type: 'invalid_type' }]
              },
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for invalid field type' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('invalid_field_type')
    end

    it 'has error severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:error)
    end

    it 'includes action name in message' do
      findings = validator.validate
      expect(findings.first.message).to include('test_action')
    end

    it 'includes invalid type in message' do
      findings = validator.validate
      expect(findings.first.message).to include('invalid_type')
    end

    it 'includes valid types in suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('string')
      expect(findings.first.suggested_fix).to include('integer')
    end
  end

  context 'with invalid field type in trigger' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              input_fields: lambda { |connection|
                [{ name: 'field', type: 'wrong_type' }]
              },
              poll: lambda { |connection, input, closure| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for invalid field type' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('invalid_field_type')
    end

    it 'includes trigger name in message' do
      findings = validator.validate
      expect(findings.first.message).to include('test_trigger')
    end
  end

  context 'with multiple invalid field types' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              input_fields: lambda { |connection|
                [
                  { name: 'field1', type: 'bad_type1' },
                  { name: 'field2', type: 'bad_type2' }
                ]
              },
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for each invalid field type' do
      findings = validator.validate
      expect(findings.size).to eq(2)
      expect(findings.map(&:rule_name)).to all(eq('invalid_field_type'))
    end
  end

  context 'with fields without type specification' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              input_fields: lambda { |connection|
                [{ name: 'typeless_field' }]
              },
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array (type is optional)' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with no actions or triggers' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
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

  context 'with string key types (quoted)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              input_fields: lambda { |connection|
                [{ 'name' => 'field', 'type' => 'string' }]
              },
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array for valid string key types' do
      expect(validator.validate).to be_empty
    end
  end
end
