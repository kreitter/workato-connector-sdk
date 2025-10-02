# frozen_string_literal: true

RSpec.describe Workato::Connector::Sdk::Validation::ConnectorStructure do
  let(:valid_connector_code) do
    <<~RUBY
      {
        title: 'Test Connector',
        connection: {
          fields: [{ name: 'api_key' }],
          authorization: {
            type: 'custom_auth',
            apply: -> (connection) { }
          }
        },
        test: -> (connection) { get('/test') },
        actions: {
          get_record: {
            execute: -> (connection, input) { }
          }
        },
        triggers: {
          new_record: {
            poll: -> (connection, input, closure) { }
          }
        },
        object_definitions: {
          record: {
            fields: -> { [{ name: 'id' }] }
          }
        },
        pick_lists: {
          statuses: -> { [['Active', 'active']] }
        }
      }
    RUBY
  end

  let(:invalid_syntax_code) do
    "{ title: 'Test', connection: {"
  end

  describe '#initialize' do
    it 'accepts source_code string' do
      structure = described_class.new(valid_connector_code)
      expect(structure.source_code).to eq(valid_connector_code)
    end

    it 'initializes with syntax_valid = false' do
      structure = described_class.new(valid_connector_code)
      expect(structure.syntax_valid).to be false
    end
  end

  describe '#parse!' do
    context 'with valid Ruby syntax' do
      let(:structure) { described_class.new(valid_connector_code) }

      before { structure.parse! }

      it 'sets syntax_valid to true' do
        expect(structure.syntax_valid).to be true
      end

      it 'populates ast with Ripper S-expression' do
        expect(structure.ast).not_to be_nil
      end

      it 'extracts connector_hash from AST' do
        expect(structure.connector_hash).to be_a(Hash)
        expect(structure.connector_hash[:title]).to eq('Test Connector')
      end
    end

    context 'with invalid Ruby syntax' do
      let(:structure) { described_class.new(invalid_syntax_code) }

      before { structure.parse! }

      it 'sets syntax_valid to false' do
        expect(structure.syntax_valid).to be false
      end

      it 'populates parse_errors with error messages' do
        expect(structure.parse_errors).not_to be_empty
      end

      it 'includes line numbers in error messages' do
        expect(structure.parse_errors.first).to match(/line \d+/)
      end
    end
  end

  describe 'derived attributes' do
    let(:structure) { described_class.new(valid_connector_code) }

    before { structure.parse! }

    it 'extracts title from connector_hash[:title]' do
      expect(structure.title).to eq('Test Connector')
    end

    it 'extracts connection from connector_hash[:connection]' do
      expect(structure.connection).to be_a(Hash)
      expect(structure.connection[:fields]).to be_an(Array)
    end

    it 'extracts actions from connector_hash[:actions]' do
      expect(structure.actions).to be_a(Hash)
      expect(structure.actions).to have_key(:get_record)
    end

    it 'extracts triggers from connector_hash[:triggers]' do
      expect(structure.triggers).to be_a(Hash)
      expect(structure.triggers).to have_key(:new_record)
    end

    it 'defaults to empty hash when sections missing' do
      minimal_code = '{ title: "Test", connection: {}, test: -> {} }'
      structure = described_class.new(minimal_code)
      structure.parse!

      expect(structure.actions).to eq({})
      expect(structure.triggers).to eq({})
      expect(structure.methods).to eq({})
    end
  end

  describe '#auth_type' do
    let(:structure) { described_class.new(valid_connector_code) }

    before { structure.parse! }

    it 'returns connection.dig(:authorization, :type)' do
      expect(structure.auth_type).to eq('custom_auth')
    end
  end

  describe '#defined_object_definitions' do
    let(:structure) { described_class.new(valid_connector_code) }

    before { structure.parse! }

    it 'returns array of object_definitions keys' do
      expect(structure.defined_object_definitions).to eq([:record])
    end
  end

  describe '#defined_pick_lists' do
    let(:structure) { described_class.new(valid_connector_code) }

    before { structure.parse! }

    it 'returns array of pick_lists keys' do
      expect(structure.defined_pick_lists).to eq([:statuses])
    end
  end

  describe '#section_line_number' do
    let(:structure) { described_class.new(valid_connector_code) }

    before { structure.parse! }

    it 'finds line number of given section in AST' do
      line_number = structure.section_line_number(:title)
      expect(line_number).to be_a(Integer)
      expect(line_number).to be > 0
    end
  end
end