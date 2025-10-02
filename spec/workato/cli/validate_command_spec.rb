# frozen_string_literal: true

module Workato::CLI
  RSpec.describe ValidateCommand do
    subject(:command) { described_class.new(options) }

    let(:options) { { connector: connector_path } }
    let(:connector_path) { 'spec/fixtures/validation/valid_connector_test/valid_connector.rb' }

    describe '#call' do
      context 'with valid connector' do
        it 'returns exit code 0' do
          expect(command.call).to eq(0)
        end

        it 'outputs success message' do
          expect { command.call }.to output(/Connector validation passed/).to_stdout
        end
      end

      context 'with missing required section' do
        let(:connector_path) { 'spec/fixtures/validation/missing_sections_test/missing_test_section_connector.rb' }

        it 'returns exit code 1' do
          expect { command.call }.to output.to_stdout
          expect(command.call).to eq(1)
        end

        it 'outputs error message' do
          expect { command.call }.to output(/ERROR.*Missing required section: test/).to_stdout
        end
      end

      context 'with deprecated DSL patterns' do
        let(:connector_path) { 'spec/fixtures/validation/deprecated_patterns_test/deprecated_dsl_connector.rb' }

        it 'returns exit code 2' do
          expect { command.call }.to output.to_stdout
          expect(command.call).to eq(2)
        end

        it 'outputs warning message' do
          expect { command.call }.to output(/WARNING.*deprecated/).to_stdout
        end
      end

      context 'with --output option' do
        let(:output_file) { 'tmp/test_report.json' }
        let(:options) { { connector: connector_path, output: output_file } }

        before do
          FileUtils.mkdir_p('tmp')
        end

        after do
          FileUtils.rm_f(output_file)
        end

        it 'writes JSON report to file' do
          command.call
          expect(File.exist?(output_file)).to be true

          report = JSON.parse(File.read(output_file))
          expect(report).to include('connector_path', 'validated_at', 'status', 'findings')
        end
      end

      context 'with non-existent file' do
        let(:connector_path) { 'nonexistent.rb' }

        it 'returns exit code 1' do
          expect { command.call }.to output(/ERROR.*not found/).to_stdout
          expect(command.call).to eq(1)
        end
      end

      context 'with --verbose option' do
        let(:options) { { connector: connector_path, verbose: true } }

        it 'shows detailed validation output' do
          expect { command.call }.to output(/All validation checks passed|Connector validation passed/).to_stdout
        end
      end
    end
  end
end
