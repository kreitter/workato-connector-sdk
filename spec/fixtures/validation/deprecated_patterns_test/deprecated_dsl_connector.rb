{
  title: 'Connector with Deprecated DSL',

  connection: {
    fields: [{ name: 'api_key' }],

    authorization: {
      type: 'custom_auth',
      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      end
    },

    # Using deprecated method
    after_error_response: lambda do |code, body, headers, message|
      error("#{code}: #{message}")
    end
  },

  test: lambda do |_connection|
    get('/api/test')
  end
}