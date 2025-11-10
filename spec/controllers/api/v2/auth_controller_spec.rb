require 'rails_helper'

RSpec.describe Api::V2::AuthController, type: :request do
  describe 'POST /api/v2/auth/register' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: 'John',
          last_name: 'Doe'
        }
      }
    end

    context 'with valid params' do
      it 'creates a new user' do
        expect {
          post '/api/v2/auth/register', params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'returns a token and user data' do
        post '/api/v2/auth/register', params: valid_params
        expect(response).to have_http_status(:created)
        json = json_response
        expect(json['token']).to be_present
        expect(json['user']).to be_present
        expect(json['user']['email']).to eq('newuser@example.com')
      end
    end

    context 'with invalid params' do
      it 'returns errors' do
        post '/api/v2/auth/register', params: { user: { email: 'invalid' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'POST /api/v2/auth/login' do
    let(:user) { create(:user, email: 'user@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns a token' do
        post '/api/v2/auth/login', params: { email: 'user@example.com', password: 'password123' }
        expect(response).to have_http_status(:ok)
        json = json_response
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('user@example.com')
      end
    end

    context 'with invalid credentials' do
      it 'returns error' do
        post '/api/v2/auth/login', params: { email: 'user@example.com', password: 'wrong' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'GET /api/v2/auth/me' do
    let(:user) { create(:user) }

    it 'returns current user' do
      get '/api/v2/auth/me', headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = json_response
      expect(json['user']['id']).to eq(user.id)
    end

    it 'requires authentication' do
      get '/api/v2/auth/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v2/auth/refresh' do
    let(:user) { create(:user) }

    it 'returns a new token' do
      post '/api/v2/auth/refresh', headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_response['token']).to be_present
    end
  end
end

