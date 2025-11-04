require 'rails_helper'

RSpec.describe CursorPagination, type: :controller do
  controller(Api::V2::BaseController) do
    def index
      scope = User.all
      result = paginate_with_cursor(scope, cursor_field: :id)
      render json: result
    end
  end

  let(:user) { create(:user) }

  before do
    create_list(:user, 25)
    routes.draw do
      namespace :api do
        namespace :v2 do
          get 'index' => 'base#index'
        end
      end
    end
  end

  describe 'pagination' do
    it 'returns paginated results' do
      get '/api/v2/index', headers: auth_headers(user)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
      expect(json['next_cursor']).to be_present
      expect(json['has_more']).to be_in([true, false])
    end

    it 'respects limit parameter' do
      get '/api/v2/index', headers: auth_headers(user), params: { limit: 10 }
      json = JSON.parse(response.body)
      expect(json['data'].length).to be <= 10
    end

    it 'supports cursor parameter' do
      get '/api/v2/index', headers: auth_headers(user), params: { cursor: User.first.id, limit: 5 }
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
    end
  end
end

