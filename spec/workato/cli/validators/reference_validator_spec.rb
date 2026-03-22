# frozen_string_literal: true

RSpec.describe Workato::CLI::Validators::ReferenceValidator do
  let(:validator) { described_class.new(structure) }

  # Note: The current ReferenceValidator implementation has a limitation -
  # it uses component.to_s which returns "#<Proc:...>" for lambda bodies,
  # so it cannot detect references inside lambdas. These tests document
  # the current behavior.

  context 'with no object_definition or pick_list references' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {
            simple_action: {
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

  context 'with defined object_definitions' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          object_definitions: {
            user: {
              fields: lambda { |connection| [{ name: 'id' }] }
            }
          },
          actions: {
            get_user: {
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array when object_definitions are defined' do
      expect(validator.validate).to be_empty
    end

    it 'correctly identifies defined object_definitions' do
      expect(structure.defined_object_definitions).to include(:user)
    end
  end

  context 'with defined pick_lists' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          pick_lists: {
            statuses: lambda { |connection| [['Active', 'active'], ['Inactive', 'inactive']] }
          },
          actions: {
            update_status: {
              execute: lambda { |connection, input| {} }
            }
          }
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array when pick_lists are defined' do
      expect(validator.validate).to be_empty
    end

    it 'correctly identifies defined pick_lists' do
      expect(structure.defined_pick_lists).to include(:statuses)
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

  context 'with no connector_hash (parse failure)' do
    let(:structure) do
      # Create a structure that fails to eval but has valid syntax
      code = <<~RUBY
        undefined_variable_xyz
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
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

  context 'with empty actions and triggers' do
    let(:structure) do
      code = <<~RUBY
        {
          title: 'Test',
          connection: {},
          test: lambda {},
          actions: {},
          triggers: {}
        }
      RUBY
      Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
    end

    it 'returns empty findings array' do
      expect(validator.validate).to be_empty
    end
  end

  # Note: Tests for detecting undefined references would require the validator
  # to parse the lambda source code (e.g., via Ripper or Proc#source_location),
  # which is not currently implemented. The following tests document expected
  # behavior that is not yet functional:

  describe 'reference detection (implementation pending)', pending: 'requires source code parsing' do
    context 'with undefined object_definition reference' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              get_user: {
                input_fields: lambda { |c| object_definitions[:undefined_type] },
                execute: lambda { |connection, input| {} }
              }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'would return finding for undefined reference' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('undefined_object_definition')
      end
    end

    context 'with undefined pick_list reference' do
      let(:structure) do
        code = <<~RUBY
          {
            title: 'Test',
            connection: {},
            test: lambda {},
            actions: {
              update_status: {
                input_fields: lambda { |c|
                  [{ name: 'status', pick_list: 'undefined_list' }]
                },
                execute: lambda { |connection, input| {} }
              }
            }
          }
        RUBY
        Workato::Connector::Sdk::Validation::ConnectorStructure.new(code).tap(&:parse!)
      end

      it 'would return finding for undefined pick_list' do
        findings = validator.validate
        expect(findings.size).to eq(1)
        expect(findings.first.rule_name).to eq('undefined_pick_list')
      end
    end
  end
end
