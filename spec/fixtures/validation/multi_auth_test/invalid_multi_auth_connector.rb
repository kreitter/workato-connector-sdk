{
  title: 'Invalid Multi-Auth Test Connector',

  connection: {
    fields: [
      { name: 'auth_type', control_type: 'select' }
    ],

    authorization: {
      type: 'multi'
      # Missing required keys: selected and options
    }
  },

  test: lambda do |connection|
    get('/api/test')
  end
}
