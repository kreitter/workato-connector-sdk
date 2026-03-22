{
  title: 'Invalid Poll Signature Test Connector',

  connection: {
    fields: [{ name: 'api_key', control_type: 'password' }],

    authorization: {
      type: 'custom_auth',
      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      end
    }
  },

  test: lambda do |connection|
    get('/api/test')
  end,

  triggers: {
    new_record: {
      # Invalid: poll should have at least 3 params (connection, input, closure)
      poll: lambda do |connection, input|
        records = get('/api/records')
        {
          events: records,
          next_poll: nil
        }
      end,

      output_fields: lambda do
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' }
        ]
      end
    }
  }
}
