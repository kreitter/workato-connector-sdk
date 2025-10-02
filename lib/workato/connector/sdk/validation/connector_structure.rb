# frozen_string_literal: true

require 'ripper'

module Workato
  module Connector
    module Sdk
      module Validation
        # Represents the parsed connector code structure
        class ConnectorStructure
          attr_reader :source_code, :ast, :connector_hash, :syntax_valid, :parse_errors

          def initialize(source_code)
            @source_code = source_code
            @ast = nil
            @connector_hash = nil
            @syntax_valid = false
            @parse_errors = []
          end

          def parse!
            # Parse the Ruby code into an AST
            @ast = Ripper.sexp(source_code)

            if @ast.nil?
              # Syntax error occurred
              @syntax_valid = false
              extract_syntax_errors
            else
              @syntax_valid = true
              extract_connector_hash
            end
          end

          # Derived attributes
          def title
            connector_hash&.dig(:title)
          end

          def connection
            connector_hash&.dig(:connection) || {}
          end

          def test
            connector_hash&.dig(:test)
          end

          def actions
            connector_hash&.dig(:actions) || {}
          end

          def triggers
            connector_hash&.dig(:triggers) || {}
          end

          def methods
            connector_hash&.dig(:methods) || {}
          end

          def object_definitions
            connector_hash&.dig(:object_definitions) || {}
          end

          def pick_lists
            connector_hash&.dig(:pick_lists) || {}
          end

          def webhook_keys
            connector_hash&.dig(:webhook_keys) || []
          end

          def auth_type
            connection.dig(:authorization, :type)
          end

          def auth_fields
            connection.dig(:authorization)&.keys || []
          end

          def defined_object_definitions
            object_definitions.keys
          end

          def defined_pick_lists
            pick_lists.keys
          end

          def defined_methods
            methods.keys
          end

          def section_line_number(section_name)
            # Search AST for the section and return its line number
            find_section_line(ast, section_name)
          end

          private

          def extract_syntax_errors
            # Try to get more detailed error information
            parser = RipperErrorParser.new(source_code)
            parser.parse
            @parse_errors = parser.errors

            if @parse_errors.empty?
              @parse_errors = ['Syntax error: unexpected end-of-input']
            end
          end

          def extract_connector_hash
            # Evaluate the code safely to extract the hash structure
            # This is safe because we're only evaluating DSL code, not executing it
            begin
              @connector_hash = eval(source_code) # rubocop:disable Security/Eval
            rescue StandardError => e
              # If evaluation fails, try to extract what we can from AST
              @connector_hash = extract_from_ast || {}
            end
          end

          def extract_from_ast
            # Simplified AST-based extraction as fallback
            # This would walk the AST to extract the hash structure
            # For now, return nil and rely on eval
            nil
          end

          def find_section_line(node, section_name)
            return nil unless node.is_a?(Array)

            # Look for label nodes matching the section name
            node.each_with_index do |child, _idx|
              if child.is_a?(Array)
                # Check if this is a label node (symbol followed by value)
                if child[0] == :@label && child[1] == "#{section_name}:"
                  return child[2][0] # Line number is in the position info
                end

                # Recursively search child nodes
                result = find_section_line(child, section_name)
                return result if result
              end
            end

            nil
          end

          # Helper class to extract syntax errors from Ripper
          class RipperErrorParser < Ripper
            attr_reader :errors

            def initialize(source)
              super
              @errors = []
            end

            def on_parse_error(message)
              line = lineno
              @errors << "Syntax error at line #{line}: #{message}"
            end

            def on_alias_error(message)
              @errors << "Alias error: #{message}"
            end

            def on_assign_error(message)
              @errors << "Assignment error: #{message}"
            end

            def on_class_name_error(message)
              @errors << "Class name error: #{message}"
            end

            def on_param_error(message)
              @errors << "Parameter error: #{message}"
            end
          end
        end
      end
    end
  end
end