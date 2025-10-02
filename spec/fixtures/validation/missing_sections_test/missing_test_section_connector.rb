{
  title: 'Connector Missing Test',

  connection: {
    fields: [
      { name: 'api_key', control_type: 'password' }
    ],

    authorization: {
      type: 'custom_auth',
      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      end
    }
  }

  # Missing test: block - this should trigger validation error
}