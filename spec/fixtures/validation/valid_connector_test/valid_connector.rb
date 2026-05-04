{
  title: 'Test Connector',

  connection: {
    fields: [
      { name: 'api_key', control_type: 'password', label: 'API Key' }
    ],

    authorization: {
      type: 'custom_auth',
      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      end
    },

    base_uri: lambda do |_connection|
      'https://api.example.com'
    end
  },

  test: lambda do |connection|
    get('/api/test')
  end,

  actions: {
    get_record: {
      input_fields: lambda do
        [{ name: 'id', type: 'string', optional: false }]
      end,

      execute: lambda do |connection, input|
        get("/api/records/#{input['id']}")
      end,

      output_fields: lambda do
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'created_at', type: 'datetime' }
        ]
      end
    }
  },

  triggers: {
    new_record: {
      poll: lambda do |connection, input, closure|
        records = get('/api/records')
        {
          events: records,
          next_poll: closure
        }
      end,

      output_fields: lambda do
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' }
        ]
      end
    }
  },

  object_definitions: {
    record: {
      fields: lambda do
        [
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'status', type: 'string' }
        ]
      end
    }
  }
}