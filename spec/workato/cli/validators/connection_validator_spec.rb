# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::ConnectionValidator do
  let(:validator) { described_class.new(structure) }

  context 'with valid oauth2 authorization' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'oauth2',
              authorization_url: lambda { |connection| 'https://example.com/oauth' },
              acquire: lambda { |connection, code, redirect| {} },
              apply: lambda { |connection, token| headers('Auth' => token) }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with valid multi-auth authorization' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'multi',
              selected: lambda { |connection| connection['auth_type'] },
              options: {
                oauth2: { type: 'oauth2', authorization_url: lambda {}, acquire: lambda {}, apply: lambda {} },
                api_key: { type: 'api_key', apply: lambda {} }
              }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with missing oauth2 required keys' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'oauth2',
              apply: lambda { |connection, token| }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for missing keys' do
      findings = validator.validate
      expect(findings.size).to eq(2)
      expect(findings.map(&:rule_name)).to include('oauth2_missing_authorization_url', 'oauth2_missing_acquire')
    end

    it 'all findings are errors' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.severity).to eq(:error)
      end
    end

    it 'includes suggested fixes' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.suggested_fix).not_to be_nil
      end
    end
  end

  context 'with missing multi-auth required keys' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'multi'
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns findings for missing keys' do
      findings = validator.validate
      expect(findings.size).to eq(2)
      expect(findings.map(&:rule_name)).to include('multi_missing_selected', 'multi_missing_options')
    end

    it 'all findings are errors' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.severity).to eq(:error)
      end
    end

    it 'includes suggested fixes' do
      findings = validator.validate
      findings.each do |finding|
        expect(finding.suggested_fix).to include('Add')
      end
    end
  end

  context 'with valid basic_auth authorization' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'basic_auth',
              apply: lambda { |connection| user(connection['username']) }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with valid api_key authorization' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'api_key',
              apply: lambda { |connection| headers('API-Key' => connection['key']) }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  context 'with valid custom_auth authorization' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {
            authorization: {
              type: 'custom_auth',
              apply: lambda { |connection| headers('Custom-Auth' => connection['token']) }
            }
          },
          test: lambda { |connection| }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end
end
