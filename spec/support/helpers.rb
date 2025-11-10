module Helpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end

  def graphql_query(query, variables: {}, context: {})
    post '/graphql', params: { query: query, variables: variables }, headers: context[:headers] || {}
  end

  def graphql_response
    json_response['data']
  end

  def graphql_errors
    json_response['errors']
  end
end

RSpec.configure do |config|
  config.include Helpers, type: :request
  config.include Helpers, type: :controller
end

