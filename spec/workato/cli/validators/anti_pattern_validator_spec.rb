# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::AntiPatternValidator do
  let(:validator) { described_class.new(structure) }

  describe 'hardcoded credentials detection' do
    context 'with no hardcoded credentials' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {
              authorization: {
                type: 'api_key',
                apply: lambda { |connection| headers('Authorization' => "Bearer \#{connection['token']}") }
              }
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

    context 'with hardcoded Bearer token' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              test_action: {
                execute: lambda { |connection, input|
                  headers('Authorization' => 'Bearer HARDCODED_SECRET_FOR_TESTING')
                }
              }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for hardcoded credentials' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('hardcoded_credentials')
      end

      it 'has error severity' do
        findings = validator.validate
        expect(findings.first.severity).to eq(:error)
      end

      it 'includes suggested fix' do
        findings = validator.validate
        expect(findings.first.suggested_fix).to include('connection parameters')
      end
    end

    context 'with hardcoded api_key' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              test_action: {
                execute: lambda { |connection, input|
                  params(api_key: 'sk_1234567890abcdefghij')
                }
              }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for hardcoded credentials' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('hardcoded_credentials')
      end
    end

    context 'with hardcoded token' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              test_action: {
                execute: lambda { |connection, input|
                  params(token: 'abcdefghijklmnopqrstu')
                }
              }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for hardcoded credentials' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('hardcoded_credentials')
      end
    end

    context 'with short tokens (not flagged)' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              test_action: {
                execute: lambda { |connection, input|
                  params(api_key: 'short')
                }
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
  end

  describe 'methods block validation' do
    context 'with valid lambda methods' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            methods: {
              format_date: lambda { |date| date.strftime('%Y-%m-%d') },
              parse_response: lambda { |response| JSON.parse(response) }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns empty findings array' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with non-lambda in methods block' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            methods: {
              format_date: lambda { |date| date.strftime('%Y-%m-%d') },
              not_a_lambda: 'string value'
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for non-lambda method' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('methods_non_lambda')
      end

      it 'has error severity' do
        findings = validator.validate
        expect(findings.first.severity).to eq(:error)
      end

      it 'includes method name in message' do
        findings = validator.validate
        expect(findings.first.message).to include('not_a_lambda')
      end
    end
  end

  describe 'action and trigger name validation' do
    context 'with valid action names' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              get_user: { execute: lambda {} },
              create_record: { execute: lambda {} },
              _internal_action: { execute: lambda {} }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns empty findings array' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with valid trigger names' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            triggers: {
              new_record: { poll: lambda {} },
              updated_user: { poll: lambda {} }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns empty findings array' do
        expect(validator.validate).to be_empty
      end
    end

    context 'with action name containing special characters' do
      let(:structure) do
        code = <<~'RUBY'
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              'get-user': { execute: lambda {} }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for invalid action name' do
        findings = validator.validate
        # The action name 'get-user' contains a hyphen which is invalid
        invalid_name_findings = findings.select { |f| f.rule_name == 'invalid_action_name' }
        expect(invalid_name_findings.size).to eq(1)
      end

      it 'has error severity' do
        findings = validator.validate.select { |f| f.rule_name == 'invalid_action_name' }
        expect(findings.first.severity).to eq(:error)
      end

      it 'includes suggested fix' do
        findings = validator.validate.select { |f| f.rule_name == 'invalid_action_name' }
        expect(findings.first.suggested_fix).to include('underscore')
      end
    end

    context 'with action name starting with number' do
      let(:structure) do
        code = <<~'RUBY'
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              '123_action': { execute: lambda {} }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'returns finding for invalid action name' do
        findings = validator.validate.select { |f| f.rule_name == 'invalid_action_name' }
        expect(findings.size).to eq(1)
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

  context 'with no methods, actions, or triggers' do
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
end
