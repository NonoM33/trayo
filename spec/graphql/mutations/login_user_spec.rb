require 'rails_helper'

RSpec.describe 'GraphQL Mutations', type: :request do
  describe 'loginUser mutation' do
    let(:user) { create(:user, email: 'user@example.com', password: 'password123') }
    let(:mutation) do
      <<~GQL
        mutation {
          loginUser(email: "user@example.com", password: "password123") {
            token
            user {
              id
              email
            }
            errors {
              field
              message
            }
          }
        }
      GQL
    end

    it 'returns token on successful login' do
      post '/graphql', params: { query: mutation }
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['loginUser']['token']).to be_present
      expect(json['data']['loginUser']['user']['email']).to eq('user@example.com')
    end

    it 'returns errors on invalid credentials' do
      mutation_invalid = mutation.gsub('password123', 'wrongpassword')
      post '/graphql', params: { query: mutation_invalid }
      json = json_response
      expect(json['data']['loginUser']['errors']).to be_present
      expect(json['data']['loginUser']['token']).to be_nil
    end
  end

  describe 'registerUser mutation' do
    let(:mutation) do
      <<~GQL
        mutation {
          registerUser(
            email: "newuser@example.com"
            password: "password123"
            passwordConfirmation: "password123"
            firstName: "John"
            lastName: "Doe"
          ) {
            token
            user {
              id
              email
            }
            errors {
              field
              message
            }
          }
        }
      GQL
    end

    it 'creates a new user' do
      expect {
        post '/graphql', params: { query: mutation }
      }.to change(User, :count).by(1)
    end

    it 'returns token and user data' do
      post '/graphql', params: { query: mutation }
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['registerUser']['token']).to be_present
      expect(json['data']['registerUser']['user']['email']).to eq('newuser@example.com')
    end
  end

  describe 'purchaseBot mutation' do
    let(:user) { create(:user) }
    let(:bot) { create(:trading_bot) }
    let(:mutation) do
      <<~GQL
        mutation {
          purchaseBot(botId: "#{bot.id}") {
            botPurchase {
              id
              pricePaid
              status
              tradingBot {
                id
                name
              }
            }
            errors {
              field
              message
            }
          }
        }
      GQL
    end

    it 'creates a bot purchase' do
      post '/graphql', params: { query: mutation }, headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['purchaseBot']['botPurchase']).to be_present
      expect(json['data']['purchaseBot']['botPurchase']['tradingBot']['id']).to eq(bot.id.to_s)
    end
  end
end

