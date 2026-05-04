# frozen_string_literal: true

RSpec.describe 'Workato Validate Quickstart Scenarios', :acceptance do
  describe 'Scenario 1: Valid Connector' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/valid_connector_test/valid_connector.rb'
      )
    end

    it 'passes validation with exit code 0' do
      expect { command.call }.to output(/Connector validation passed/).to_stdout
      expect(command.call).to eq(0)
    end
  end

  describe 'Scenario 2: Missing Required Section' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/missing_sections_test/missing_test_section_connector.rb'
      )
    end

    it 'fails validation with exit code 1' do
      expect { command.call }.to output(/ERROR/).to_stdout
      expect(command.call).to eq(1)
    end

    it 'reports missing test section' do
      expect { command.call }.to output(/Missing required section: test/).to_stdout
    end
  end

  describe 'Scenario 3: Invalid Syntax' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/invalid_syntax_test/invalid_syntax_connector.rb'
      )
    end

    it 'fails validation with syntax error' do
      expect { command.call }.to output(/syntax error/).to_stdout
      expect(command.call).to eq(1)
    end
  end

  describe 'Scenario 4: Deprecated DSL Patterns' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/deprecated_patterns_test/deprecated_dsl_connector.rb'
      )
    end

    it 'passes with warnings (exit code 2)' do
      expect { command.call }.to output(/WARNING/).to_stdout
      expect(command.call).to eq(2)
    end

    it 'reports deprecated patterns' do
      expect { command.call }.to output(/deprecated/).to_stdout
    end
  end

  describe 'Scenario 5: Custom File Path' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/valid_connector_test/valid_connector.rb'
      )
    end

    it 'validates file at custom path' do
      expect { command.call }.to output(/valid_connector\.rb/).to_stdout
      expect(command.call).to eq(0)
    end
  end

  describe 'Scenario 6: Verbose Output' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/valid_connector_test/valid_connector.rb',
        verbose: true
      )
    end

    it 'shows detailed validation checks' do
      output = capture_stdout { command.call }
      expect(output).to match(/All validation checks passed|Connector validation passed/)
    end
  end

  describe 'Scenario 7: JSON Output for CI/CD' do
    let(:output_file) { 'tmp/acceptance_report.json' }
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'spec/fixtures/validation/valid_connector_test/valid_connector.rb',
        output: output_file
      )
    end

    before { FileUtils.mkdir_p('tmp') }
    after { FileUtils.rm_f(output_file) }

    it 'writes JSON report to file' do
      command.call
      expect(File.exist?(output_file)).to be true

      report = JSON.parse(File.read(output_file))
      expect(report['status']).to eq('pass')
      expect(report).to include('connector_path', 'validated_at', 'findings')
    end
  end

  describe 'Edge Case 1: Non-Existent File' do
    let(:command) do
      Workato::CLI::ValidateCommand.new(
        connector: 'nonexistent_connector.rb'
      )
    end

    it 'shows clear error message' do
      expect { command.call }.to output(/ERROR.*not found/).to_stdout
      expect(command.call).to eq(1)
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
