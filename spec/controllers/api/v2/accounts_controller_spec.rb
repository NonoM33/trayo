require 'rails_helper'

RSpec.describe Api::V2::AccountsController, type: :request do
  let(:user) { create(:user, :with_accounts) }
  let(:account) { user.mt5_accounts.first }

  describe 'GET /api/v2/accounts' do
    it 'returns user accounts' do
      get '/api/v2/accounts', headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']).to be_an(Array)
      expect(json['data'].length).to eq(2)
    end

    it 'supports pagination' do
      get '/api/v2/accounts', headers: auth_headers(user), params: { limit: 1 }
      json = json_response
      expect(json['data'].length).to eq(1)
      expect(json['next_cursor']).to be_present
    end

    it 'supports filters' do
      get '/api/v2/accounts', headers: auth_headers(user), params: { 
        'filters[account_name][like]' => account.account_name 
      }
      json = json_response
      expect(json['data'].any? { |a| a['account_name'] == account.account_name }).to be true
    end
  end

  describe 'GET /api/v2/accounts/:id' do
    it 'returns account details' do
      get "/api/v2/accounts/#{account.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['account']['id']).to eq(account.id)
    end

    it 'returns 404 for non-existent account' do
      get '/api/v2/accounts/99999', headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v2/accounts/:id/balance' do
    it 'returns account balance' do
      get "/api/v2/accounts/#{account.id}/balance", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['balance']).to eq(account.balance)
      expect(json['net_gains']).to be_present
    end
  end

  describe 'GET /api/v2/accounts/:id/trades' do
    before do
      create_list(:trade, 5, mt5_account: account)
    end

    it 'returns account trades' do
      get "/api/v2/accounts/#{account.id}/trades", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['data']).to be_an(Array)
    end

    it 'supports pagination' do
      get "/api/v2/accounts/#{account.id}/trades", headers: auth_headers(user), params: { limit: 2 }
      json = json_response
      expect(json['data'].length).to eq(2)
    end
  end

  describe 'GET /api/v2/accounts/:id/projection' do
    before do
      create_list(:trade, 10, mt5_account: account, profit: 50.0, close_time: 1.day.ago)
    end

    it 'returns projection data' do
      get "/api/v2/accounts/#{account.id}/projection", headers: auth_headers(user), params: { days: 30 }
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['projected_balance']).to be_present
      expect(json['daily_average']).to be_present
    end
  end

  describe 'GET /api/v2/accounts/:id/stats' do
    before do
      create(:trade, :winning, mt5_account: account)
      create(:trade, :losing, mt5_account: account)
    end

    it 'returns account statistics' do
      get "/api/v2/accounts/#{account.id}/stats", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['total_trades']).to eq(2)
      expect(json['win_rate']).to be_present
    end
  end
end

