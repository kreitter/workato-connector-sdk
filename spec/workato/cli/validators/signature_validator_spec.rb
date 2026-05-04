# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::SignatureValidator do
  let(:validator) { described_class.new(structure) }

  context 'with valid action execute signature' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input| { result: 'ok' } }
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

  context 'with valid trigger poll signature (3 params)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              poll: lambda { |connection, input, closure|
                { events: [], next_poll: closure }
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

  context 'with valid trigger poll signature (5 params with extended schemas)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              poll: lambda { |connection, input, closure, eis, eos|
                { events: [], next_poll: closure }
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

  context 'with invalid trigger poll signature (only 2 params)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              poll: lambda { |connection, input|
                { events: [] }
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding with severity :error' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.severity).to eq(:error)
    end

    it 'identifies invalid_poll_signature rule' do
      findings = validator.validate
      expect(findings.first.rule_name).to eq('invalid_poll_signature')
    end

    it 'includes closure in message' do
      findings = validator.validate
      expect(findings.first.message).to include('closure')
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('connection, input, closure')
    end
  end

  context 'with invalid trigger poll signature (only 1 param)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              poll: lambda { |connection|
                { events: [] }
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding with error severity' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.severity).to eq(:error)
    end
  end

  context 'with invalid action execute signature (only 1 param)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection| { result: 'ok' } }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding with severity :error' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.severity).to eq(:error)
    end

    it 'identifies invalid_execute_signature rule' do
      findings = validator.validate
      expect(findings.first.rule_name).to eq('invalid_execute_signature')
    end

    it 'includes suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('connection, input')
    end
  end

  context 'with webhook trigger missing required blocks' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            webhook_trigger: {
              type: 'webhook'
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for missing webhook blocks' do
      findings = validator.validate
      expect(findings.size).to eq(2)
      rule_names = findings.map(&:rule_name)
      expect(rule_names).to include('missing_webhook_subscribe')
      expect(rule_names).to include('missing_webhook_notification')
    end

    it 'all findings are errors' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.severity).to eq(:error)
      end
    end
  end

  context 'with variable arguments (arity -1)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          triggers: {
            test_trigger: {
              poll: lambda { |*args| { events: [] } }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array for variable args' do
      expect(validator.validate).to be_empty
    end
  end
end
