{
  title: 'Multi-Auth Test Connector',

  connection: {
    fields: [
      {
        name: 'auth_type',
        control_type: 'select',
        pick_list: [
          ['OAuth 2.0', 'oauth2'],
          ['API Key', 'api_key']
        ],
        optional: false
      },
      {
        name: 'api_key',
        control_type: 'password',
        label: 'API Key',
        hint: 'Only required for API Key authentication'
      },
      {
        name: 'client_id',
        label: 'Client ID',
        hint: 'Only required for OAuth 2.0'
      },
      {
        name: 'client_secret',
        control_type: 'password',
        label: 'Client Secret',
        hint: 'Only required for OAuth 2.0'
      }
    ],

    authorization: {
      type: 'multi',

      selected: lambda do |connection|
        connection['auth_type']
      end,

      options: {
        oauth2: {
          type: 'oauth2',

          authorization_url: lambda do |connection|
            'https://api.example.com/oauth/authorize'
          end,

          token_url: lambda do |connection|
            'https://api.example.com/oauth/token'
          end,

          client_id: lambda do |connection|
            connection['client_id']
          end,

          client_secret: lambda do |connection|
            connection['client_secret']
          end,

          apply: lambda do |connection, access_token|
            headers(Authorization: "Bearer #{access_token}")
          end
        },

        api_key: {
          type: 'custom_auth',

          apply: lambda do |connection|
            params(api_key: connection['api_key'])
          end
        }
      }
    },

    base_uri: lambda do |connection|
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
          { name: 'name', type: 'string' }
        ]
      end
    }
  }
}
