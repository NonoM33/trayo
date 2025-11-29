require 'rails_helper'

RSpec.describe 'Admin::TradeDefenders', type: :request do
  let(:admin) { create(:user, is_admin: true) }
  let(:client) { create(:user, is_admin: false) }
  let(:mt5_account) { create(:mt5_account, user: client, balance: 10000.0, high_watermark: 10000.0) }

  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_user).and_return(admin)
    allow_any_instance_of(Admin::TradeDefendersController).to receive(:current_user).and_return(admin)
  end

  describe 'GET /admin/trade_defenders' do
    before do
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_admin', magic_number: 0)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', magic_number: 0)
    end

    it 'shows pending trades by default' do
      get '/admin/trade_defenders'
      expect(response).to be_successful
      expect(response.body).to include('En attente')
    end

    it 'filters by status=all' do
      get '/admin/trade_defenders', params: { status: 'all' }
      expect(response).to be_successful
    end

    it 'filters by specific status' do
      get '/admin/trade_defenders', params: { status: 'manual_client' }
      expect(response).to be_successful
    end
  end

  describe 'POST /admin/trade_defenders/:id/approve_trade' do
    let!(:pending_trade) do
      create(:trade,
        mt5_account: mt5_account,
        trade_originality: 'manual_pending_review',
        magic_number: 0,
        profit: 100.0
      )
    end

    it 'marks trade as manual_admin' do
      post "/admin/trade_defenders/#{pending_trade.id}/approve_trade"
      pending_trade.reload
      expect(pending_trade.trade_originality).to eq('manual_admin')
      expect(pending_trade.is_unauthorized_manual).to be false
    end

    it 'does not affect watermark for pending trade' do
      initial_watermark = mt5_account.high_watermark
      post "/admin/trade_defenders/#{pending_trade.id}/approve_trade"
      expect(mt5_account.reload.high_watermark).to eq(initial_watermark)
    end

    it 'redirects with success notice' do
      post "/admin/trade_defenders/#{pending_trade.id}/approve_trade"
      expect(response).to redirect_to(admin_trade_defenders_path(status: 'manual_pending_review'))
    end

    context 'when reversing a client trade' do
      let!(:client_trade) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_client',
          is_unauthorized_manual: true,
          magic_number: 0,
          profit: 100.0
        )
      end

      before do
        mt5_account.update!(high_watermark: 9900.0)
      end

      it 'restores watermark when changing from client to admin' do
        post "/admin/trade_defenders/#{client_trade.id}/approve_trade"
        expect(mt5_account.reload.high_watermark).to eq(10000.0)
      end
    end
  end

  describe 'POST /admin/trade_defenders/:id/mark_as_client_trade' do
    let!(:pending_trade) do
      create(:trade,
        mt5_account: mt5_account,
        trade_originality: 'manual_pending_review',
        magic_number: 0,
        profit: 100.0
      )
    end

    it 'marks trade as manual_client' do
      post "/admin/trade_defenders/#{pending_trade.id}/mark_as_client_trade"
      pending_trade.reload
      expect(pending_trade.trade_originality).to eq('manual_client')
      expect(pending_trade.is_unauthorized_manual).to be true
    end

    it 'applies penalty to watermark' do
      initial_watermark = mt5_account.high_watermark
      post "/admin/trade_defenders/#{pending_trade.id}/mark_as_client_trade"
      expect(mt5_account.reload.high_watermark).to eq(initial_watermark - 100.0)
    end

    it 'handles negative profit (loss) correctly' do
      losing_trade = create(:trade,
        mt5_account: mt5_account,
        trade_originality: 'manual_pending_review',
        magic_number: 0,
        profit: -50.0
      )
      
      initial_watermark = mt5_account.high_watermark
      post "/admin/trade_defenders/#{losing_trade.id}/mark_as_client_trade"
      expect(mt5_account.reload.high_watermark).to eq(initial_watermark - 50.0)
    end

    it 'redirects with success notice' do
      post "/admin/trade_defenders/#{pending_trade.id}/mark_as_client_trade"
      expect(response).to redirect_to(admin_trade_defenders_path(status: 'manual_pending_review'))
    end
  end

  describe 'POST /admin/trade_defenders/bulk_mark_as_admin' do
    let!(:trade1) { create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 50.0) }
    let!(:trade2) { create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 75.0) }
    let!(:trade3) { create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 100.0) }

    it 'marks multiple trades as admin' do
      post '/admin/trade_defenders/bulk_mark_as_admin', params: { trade_ids: [trade1.id, trade2.id] }
      
      expect(trade1.reload.trade_originality).to eq('manual_admin')
      expect(trade2.reload.trade_originality).to eq('manual_admin')
      expect(trade3.reload.trade_originality).to eq('manual_pending_review')
    end

    it 'restores watermark for previously client trades' do
      trade1.update!(trade_originality: 'manual_client', is_unauthorized_manual: true)
      mt5_account.update!(high_watermark: 9950.0)
      
      post '/admin/trade_defenders/bulk_mark_as_admin', params: { trade_ids: [trade1.id] }
      expect(mt5_account.reload.high_watermark).to eq(10000.0)
    end

    it 'handles empty trade_ids' do
      post '/admin/trade_defenders/bulk_mark_as_admin', params: { trade_ids: [] }
      expect(response).to redirect_to(admin_trade_defenders_path(status: 'manual_pending_review'))
    end
  end

  describe 'POST /admin/trade_defenders/bulk_mark_as_client' do
    let!(:trade1) { create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 50.0) }
    let!(:trade2) { create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 75.0) }

    it 'marks multiple trades as client' do
      post '/admin/trade_defenders/bulk_mark_as_client', params: { trade_ids: [trade1.id, trade2.id] }
      
      expect(trade1.reload.trade_originality).to eq('manual_client')
      expect(trade2.reload.trade_originality).to eq('manual_client')
      expect(trade1.is_unauthorized_manual).to be true
      expect(trade2.is_unauthorized_manual).to be true
    end

    it 'applies penalties for all trades' do
      initial_watermark = mt5_account.high_watermark
      post '/admin/trade_defenders/bulk_mark_as_client', params: { trade_ids: [trade1.id, trade2.id] }
      expect(mt5_account.reload.high_watermark).to eq(initial_watermark - 125.0)
    end
  end

  describe 'POST /admin/trade_defenders/mark_all_pending_as_admin' do
    before do
      create_list(:trade, 5, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0)
    end

    it 'marks all pending trades as admin' do
      expect { post '/admin/trade_defenders/mark_all_pending_as_admin' }
        .to change { Trade.where(trade_originality: 'manual_admin').count }.from(0).to(5)
    end

    it 'clears all pending trades' do
      expect { post '/admin/trade_defenders/mark_all_pending_as_admin' }
        .to change { Trade.where(trade_originality: 'manual_pending_review').count }.from(5).to(0)
    end
  end

  describe 'POST /admin/trade_defenders/mark_all_pending_as_client' do
    before do
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 100.0)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0, profit: 50.0)
    end

    it 'marks all pending trades as client' do
      expect { post '/admin/trade_defenders/mark_all_pending_as_client' }
        .to change { Trade.where(trade_originality: 'manual_client').count }.from(0).to(2)
    end

    it 'applies penalties for all trades' do
      initial_watermark = mt5_account.high_watermark
      post '/admin/trade_defenders/mark_all_pending_as_client'
      expect(mt5_account.reload.high_watermark).to eq(initial_watermark - 150.0)
    end
  end
end
