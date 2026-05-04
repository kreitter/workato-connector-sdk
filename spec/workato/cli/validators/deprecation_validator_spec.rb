# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::DeprecationValidator do
  let(:validator) { described_class.new(structure) }

  context 'with no deprecated patterns' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input|
                response = get('/api/data')
                error_handler do |error|
                  puts error
                end
                response
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

  context 'with deprecated after_error_response' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input|
                get('/api/data').after_error_response(400) do |code, body|
                  error("API error: \#{body}")
                end
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for deprecated method' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('deprecated_dsl_method')
    end

    it 'has warning severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:warning)
    end

    it 'mentions the deprecated method' do
      findings = validator.validate
      expect(findings.first.message).to include('after_error_response')
    end

    it 'includes replacement in suggested fix' do
      findings = validator.validate
      expect(findings.first.suggested_fix).to include('error_handler')
    end
  end

  context 'with deprecated request_format_www_form_urlencoded' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input|
                post('/api/submit').request_format_www_form_urlencoded
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns finding for deprecated method' do
      findings = validator.validate
      expect(findings.size).to eq(1)
      expect(findings.first.rule_name).to eq('deprecated_dsl_method')
    end

    it 'has info severity' do
      findings = validator.validate
      expect(findings.first.severity).to eq(:info)
    end
  end

  context 'with multiple deprecated patterns' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input|
                post('/api/submit')
                  .request_format_www_form_urlencoded
                  .after_error_response(400) { |c, b| error(b) }
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for all deprecated patterns' do
      findings = validator.validate
      expect(findings.size).to eq(2)
      expect(findings.map(&:rule_name)).to all(eq('deprecated_dsl_method'))
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

  context 'with deprecated pattern in comments (should still detect)' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          # Use after_error_response for backward compatibility
          actions: {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'detects deprecated pattern in comments' do
      # The validator uses simple string matching, so comments are included
      findings = validator.validate
      expect(findings.size).to eq(1)
    end
  end

  context 'with context information' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            test_action: {
              execute: lambda { |connection, input|
                get('/api/data').after_error_response(400) { |c, b| error(b) }
              }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'includes context with deprecated method name' do
      findings = validator.validate
      expect(findings.first.context[:deprecated_method]).to eq('after_error_response')
    end

    it 'includes context with replacement method' do
      findings = validator.validate
      expect(findings.first.context[:replacement]).to eq('error_handler')
    end
  end
end
