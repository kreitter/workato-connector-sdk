# frozen_string_literal: true

module Workato
  module CLI
    module Validators
      # Validates connection authorization (FR-003)
      class ConnectionValidator < BaseValidator
        AUTH_REQUIREMENTS = {
          'oauth2' => {
            required: %i[authorization_url acquire apply],
            optional: %i[refresh refresh_on detect_on]
          },
          'basic_auth' => {
            required: %i[apply],
            optional: %i[detect_on]
          },
          'api_key' => {
            required: %i[apply],
            optional: %i[detect_on]
          },
          'custom_auth' => {
            required: %i[apply],
            optional: []
          },
          'multi' => {
            required: %i[selected options],
            optional: []
          }
        }.freeze

        def validate
          findings = []

          return findings unless structure.syntax_valid
          return findings unless structure.connection

          auth = structure.connection[:authorization]
          return findings unless auth

          auth_type = auth[:type] || auth['type']
          return findings unless auth_type

          requirements = AUTH_REQUIREMENTS[auth_type.to_s]
          return findings unless requirements

          requirements[:required].each do |required_key|
            next if auth.key?(required_key) || auth.key?(required_key.to_s)

            findings << report_finding(
              rule_name: "#{auth_type}_missing_#{required_key}",
              severity: :error,
              message: "#{auth_type.capitalize} authorization missing required key: #{required_key}",
              suggested_fix: suggested_fix_for(auth_type, required_key),
              context: {
                auth_type: auth_type,
                missing_key: required_key,
                present_keys: auth.keys
              }
            )
          end

          findings
        end

        private

        def suggested_fix_for(auth_type, key)
          case key
          when :authorization_url
            'Add authorization_url: lambda { |connection| ... } to authorization block'
          when :acquire
            'Add acquire: lambda { |connection, auth_code, redirect_uri| ... } to authorization block'
          when :apply
            'Add apply: lambda { |connection| ... } to authorization block'
          when :refresh
            'Add refresh: lambda { |connection, refresh_token| ... } to authorization block'
          when :selected
            "Add selected: lambda { |connection| connection['auth_type'] } to authorization block"
          when :options
            "Add options: { option_name: { type: '...', ... } } to authorization block"
          else
            "Add #{key}: ... to authorization block"
          end
        end
      end
    end
  end
end