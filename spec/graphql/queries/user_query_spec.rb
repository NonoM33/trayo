require 'rails_helper'

RSpec.describe 'GraphQL Queries', type: :request do
  describe 'user query' do
    let(:user) { create(:user, :with_accounts) }
    let(:query) do
      <<~GQL
        query {
          user {
            id
            email
            firstName
            lastName
            mt5Accounts {
              id
              mt5Id
              accountName
              balance
            }
          }
        }
      GQL
    end

    it 'returns current user' do
      post '/graphql', params: { query: query }, headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['user']).to be_present
      expect(json['data']['user']['email']).to eq(user.email)
    end

    it 'requires authentication' do
      post '/graphql', params: { query: query }
      json = json_response
      expect(json['data']['user']).to be_nil
    end
  end

  describe 'mt5Accounts query' do
    let(:user) { create(:user, :with_accounts) }
    let(:query) do
      <<~GQL
        query {
          mt5Accounts {
            id
            mt5Id
            accountName
            balance
          }
        }
      GQL
    end

    it 'returns user accounts' do
      post '/graphql', params: { query: query }, headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['mt5Accounts']).to be_an(Array)
      expect(json['data']['mt5Accounts'].length).to eq(2)
    end
  end

  describe 'dashboard query' do
    let(:user) { create(:user, :with_accounts) }
    let(:query) do
      <<~GQL
        query {
          dashboard {
            totalBalance
            totalProfits
            balanceDue
            accountsCount
            botsCount
          }
        }
      GQL
    end

    it 'returns dashboard data' do
      post '/graphql', params: { query: query }, headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']['dashboard']).to be_present
      expect(json['data']['dashboard']['accountsCount']).to eq(2)
    end
  end
end

