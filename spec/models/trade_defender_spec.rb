require 'rails_helper'

RSpec.describe 'Trade Defender - Classification des trades manuels', type: :model do
  let(:user) { create(:user) }
  let(:mt5_account) { create(:mt5_account, user: user, balance: 10000.0, high_watermark: 10000.0) }

  describe 'Trade#detect_trade_originality!' do
    context 'when magic_number is 0 (manual trade)' do
      let(:trade) { build(:trade, mt5_account: mt5_account, magic_number: 0) }

      it 'classifies as manual_pending_review' do
        trade.detect_trade_originality!
        expect(trade.trade_originality).to eq('manual_pending_review')
      end

      it 'sets is_unauthorized_manual to false initially' do
        trade.detect_trade_originality!
        expect(trade.is_unauthorized_manual).to be false
      end
    end

    context 'when magic_number is positive (bot trade)' do
      let(:trade) { build(:trade, mt5_account: mt5_account, magic_number: 12345) }

      it 'classifies as bot' do
        trade.detect_trade_originality!
        expect(trade.trade_originality).to eq('bot')
      end

      it 'sets is_unauthorized_manual to false' do
        trade.detect_trade_originality!
        expect(trade.is_unauthorized_manual).to be false
      end
    end

    context 'when magic_number is nil' do
      let(:trade) { build(:trade, mt5_account: mt5_account, magic_number: nil, trade_originality: nil) }

      it 'does not classify the trade (returns early)' do
        trade.detect_trade_originality!
        expect(trade.trade_originality).to be_nil
      end
    end

    context 'when magic_number is negative' do
      let(:trade) { build(:trade, mt5_account: mt5_account, magic_number: -1) }

      it 'classifies as bot (any non-zero value)' do
        trade.detect_trade_originality!
        expect(trade.trade_originality).to eq('bot')
      end
    end
  end

  describe 'Trade.create_or_update_from_mt5' do
    let(:trade_data) do
      {
        trade_id: 'MT5_TRADE_001',
        symbol: 'EURUSD',
        trade_type: 'buy',
        volume: 0.1,
        open_price: 1.1000,
        close_price: 1.1050,
        profit: 50.0,
        commission: -2.0,
        swap: -1.0,
        open_time: 1.hour.ago,
        close_time: Time.current,
        status: 'closed',
        magic_number: 0,
        comment: 'Test trade'
      }
    end

    it 'creates a trade with correct originality for manual trade' do
      trade = Trade.create_or_update_from_mt5(mt5_account, trade_data)
      expect(trade.trade_originality).to eq('manual_pending_review')
    end

    it 'creates a trade with correct originality for bot trade' do
      trade_data[:magic_number] = 12345
      trade = Trade.create_or_update_from_mt5(mt5_account, trade_data)
      expect(trade.trade_originality).to eq('bot')
    end

    it 'updates originality when magic_number changes from bot to manual' do
      trade_data[:magic_number] = 12345
      trade = Trade.create_or_update_from_mt5(mt5_account, trade_data)
      expect(trade.trade_originality).to eq('bot')

      trade_data[:magic_number] = 0
      updated_trade = Trade.create_or_update_from_mt5(mt5_account, trade_data)
      expect(updated_trade.trade_originality).to eq('manual_pending_review')
    end
  end

  describe 'Trade classification helper methods' do
    context '#manual_client_trade?' do
      it 'returns true when trade_originality is manual_client' do
        trade = build(:trade, trade_originality: 'manual_client')
        expect(trade.manual_client_trade?).to be true
      end

      it 'returns false for other originalities' do
        trade = build(:trade, trade_originality: 'manual_admin')
        expect(trade.manual_client_trade?).to be false
      end
    end

    context '#manual_admin_trade?' do
      it 'returns true when trade_originality is manual_admin' do
        trade = build(:trade, trade_originality: 'manual_admin')
        expect(trade.manual_admin_trade?).to be true
      end

      it 'returns false for other originalities' do
        trade = build(:trade, trade_originality: 'manual_client')
        expect(trade.manual_admin_trade?).to be false
      end
    end

    context '#bot_trade?' do
      it 'returns true when trade_originality is bot' do
        trade = build(:trade, trade_originality: 'bot')
        expect(trade.bot_trade?).to be true
      end

      it 'returns false for manual trades' do
        trade = build(:trade, trade_originality: 'manual_pending_review')
        expect(trade.bot_trade?).to be false
      end
    end
  end

  describe 'Trade scopes' do
    before do
      create(:trade, mt5_account: mt5_account, trade_originality: 'bot', magic_number: 12345)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_admin', magic_number: 0)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', magic_number: 0, is_unauthorized_manual: true)
      create(:trade, mt5_account: mt5_account, trade_originality: 'manual_pending_review', magic_number: 0)
    end

    it 'bot_trades returns only bot trades' do
      expect(Trade.bot_trades.count).to eq(1)
      expect(Trade.bot_trades.first.trade_originality).to eq('bot')
    end

    it 'manual_trades returns admin and client manual trades' do
      expect(Trade.manual_trades.count).to eq(2)
    end

    it 'admin_trades returns only admin manual trades' do
      expect(Trade.admin_trades.count).to eq(1)
      expect(Trade.admin_trades.first.trade_originality).to eq('manual_admin')
    end

    it 'client_manual_trades returns only client manual trades' do
      expect(Trade.client_manual_trades.count).to eq(1)
      expect(Trade.client_manual_trades.first.trade_originality).to eq('manual_client')
    end

    it 'unauthorized_manual returns trades marked as unauthorized' do
      expect(Trade.unauthorized_manual.count).to eq(1)
      expect(Trade.unauthorized_manual.first.is_unauthorized_manual).to be true
    end
  end

  describe 'Trade Defender Penalty System' do
    describe 'Trade#apply_trade_defender_penalty' do
      context 'when trade is manual_client and unauthorized' do
        let(:trade) do
          create(:trade,
            mt5_account: mt5_account,
            trade_originality: 'manual_client',
            is_unauthorized_manual: true,
            profit: 100.0
          )
        end

        it 'applies penalty to mt5_account watermark' do
          initial_watermark = mt5_account.high_watermark
          trade.apply_trade_defender_penalty
          mt5_account.reload
          expect(mt5_account.high_watermark).to eq(initial_watermark - 100.0)
        end
      end

      context 'when trade is manual_client but not unauthorized' do
        let(:trade) do
          create(:trade,
            mt5_account: mt5_account,
            trade_originality: 'manual_client',
            is_unauthorized_manual: false,
            profit: 100.0
          )
        end

        it 'does not apply penalty' do
          initial_watermark = mt5_account.high_watermark
          trade.apply_trade_defender_penalty
          mt5_account.reload
          expect(mt5_account.high_watermark).to eq(initial_watermark)
        end
      end

      context 'when trade is manual_admin' do
        let(:trade) do
          create(:trade,
            mt5_account: mt5_account,
            trade_originality: 'manual_admin',
            is_unauthorized_manual: false,
            profit: 100.0
          )
        end

        it 'does not apply penalty' do
          initial_watermark = mt5_account.high_watermark
          trade.apply_trade_defender_penalty
          mt5_account.reload
          expect(mt5_account.high_watermark).to eq(initial_watermark)
        end
      end

      context 'when trade has negative profit (loss)' do
        let(:trade) do
          create(:trade,
            mt5_account: mt5_account,
            trade_originality: 'manual_client',
            is_unauthorized_manual: true,
            profit: -50.0
          )
        end

        it 'still deducts absolute value from watermark' do
          initial_watermark = mt5_account.high_watermark
          trade.apply_trade_defender_penalty
          mt5_account.reload
          expect(mt5_account.high_watermark).to eq(initial_watermark - 50.0)
        end
      end
    end

    describe 'Mt5Account#apply_trade_defender_penalty' do
      it 'deducts profit from high_watermark' do
        initial = mt5_account.high_watermark
        mt5_account.apply_trade_defender_penalty(150.0)
        expect(mt5_account.reload.high_watermark).to eq(initial - 150.0)
      end

      it 'handles negative profits (uses absolute value)' do
        initial = mt5_account.high_watermark
        mt5_account.apply_trade_defender_penalty(-75.0)
        expect(mt5_account.reload.high_watermark).to eq(initial - 75.0)
      end
    end

    describe 'Mt5Account#unauthorized_manual_trades_total' do
      before do
        create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', is_unauthorized_manual: true, profit: 100.0)
        create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', is_unauthorized_manual: true, profit: -50.0)
        create(:trade, mt5_account: mt5_account, trade_originality: 'manual_admin', is_unauthorized_manual: false, profit: 200.0)
      end

      it 'sums absolute values of unauthorized manual trades only' do
        expect(mt5_account.unauthorized_manual_trades_total).to eq(150.0)
      end
    end

    describe 'Mt5Account#recalculate_watermark_with_penalties' do
      before do
        mt5_account.update!(balance: 12000.0, high_watermark: 12000.0)
        create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', is_unauthorized_manual: true, profit: 500.0)
        create(:trade, mt5_account: mt5_account, trade_originality: 'manual_client', is_unauthorized_manual: true, profit: -200.0)
      end

      it 'recalculates watermark subtracting all unauthorized trades' do
        mt5_account.recalculate_watermark_with_penalties
        expect(mt5_account.reload.high_watermark).to eq(12000.0 - 700.0)
      end
    end
  end

  describe 'Classification state transitions' do
    let(:pending_trade) do
      create(:trade,
        mt5_account: mt5_account,
        trade_originality: 'manual_pending_review',
        is_unauthorized_manual: false,
        profit: 100.0,
        magic_number: 0
      )
    end

    describe 'from pending_review to manual_admin' do
      it 'updates originality without applying penalty' do
        initial_watermark = mt5_account.high_watermark
        pending_trade.update!(trade_originality: 'manual_admin', is_unauthorized_manual: false)
        mt5_account.reload
        expect(mt5_account.high_watermark).to eq(initial_watermark)
      end
    end

    describe 'from pending_review to manual_client' do
      it 'updates originality and marks as unauthorized' do
        pending_trade.update!(trade_originality: 'manual_client', is_unauthorized_manual: true)
        expect(pending_trade.manual_client_trade?).to be true
        expect(pending_trade.is_unauthorized_manual).to be true
      end
    end

    describe 'from manual_client to manual_admin (reversal)' do
      let(:client_trade) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_client',
          is_unauthorized_manual: true,
          profit: 100.0,
          magic_number: 0
        )
      end

      before do
        mt5_account.apply_trade_defender_penalty(client_trade.profit)
      end

      it 'can be reversed to admin trade' do
        old_watermark = mt5_account.reload.high_watermark
        client_trade.update!(trade_originality: 'manual_admin', is_unauthorized_manual: false)
        mt5_account.update!(high_watermark: old_watermark + client_trade.profit.abs)
        
        expect(client_trade.manual_admin_trade?).to be true
        expect(mt5_account.reload.high_watermark).to eq(10000.0)
      end
    end
  end

  describe 'Edge cases' do
    describe 'multiple manual trades from same user' do
      before do
        3.times do |i|
          create(:trade,
            mt5_account: mt5_account,
            trade_originality: 'manual_pending_review',
            magic_number: 0,
            profit: (i + 1) * 50.0
          )
        end
      end

      it 'correctly counts pending trades' do
        expect(Trade.where(trade_originality: 'manual_pending_review').count).to eq(3)
      end

      it 'allows bulk classification' do
        Trade.where(trade_originality: 'manual_pending_review').update_all(
          trade_originality: 'manual_admin',
          is_unauthorized_manual: false
        )
        expect(Trade.where(trade_originality: 'manual_admin').count).to eq(3)
        expect(Trade.where(trade_originality: 'manual_pending_review').count).to eq(0)
      end
    end

    describe 'trade with zero profit' do
      let(:zero_profit_trade) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_client',
          is_unauthorized_manual: true,
          profit: 0.0,
          magic_number: 0
        )
      end

      it 'does not affect watermark' do
        initial = mt5_account.high_watermark
        mt5_account.apply_trade_defender_penalty(zero_profit_trade.profit)
        expect(mt5_account.reload.high_watermark).to eq(initial)
      end
    end

    describe 'very large profit values' do
      let(:large_profit_trade) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_client',
          is_unauthorized_manual: true,
          profit: 1_000_000.0,
          magic_number: 0
        )
      end

      it 'handles large values correctly' do
        mt5_account.update!(high_watermark: 2_000_000.0)
        mt5_account.apply_trade_defender_penalty(large_profit_trade.profit)
        expect(mt5_account.reload.high_watermark).to eq(1_000_000.0)
      end
    end

    describe 'watermark going negative after penalty' do
      let(:trade_exceeding_watermark) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_client',
          is_unauthorized_manual: true,
          profit: 15000.0,
          magic_number: 0
        )
      end

      it 'allows watermark to go negative' do
        mt5_account.apply_trade_defender_penalty(trade_exceeding_watermark.profit)
        expect(mt5_account.reload.high_watermark).to eq(-5000.0)
      end
    end
  end

  describe 'Bug scenarios' do
    describe 'magic_number nil not being handled' do
      let(:trade_without_magic) { build(:trade, mt5_account: mt5_account, magic_number: nil, trade_originality: nil) }

      it 'does not set trade_originality when magic_number is nil' do
        trade_without_magic.detect_trade_originality!
        expect(trade_without_magic.trade_originality).to be_nil
      end

      it 'trade can still be saved without originality' do
        trade_without_magic.save!
        expect(trade_without_magic.persisted?).to be true
        expect(trade_without_magic.trade_originality).to be_nil
      end
    end

    describe 'concurrent classification updates' do
      let(:trade) do
        create(:trade,
          mt5_account: mt5_account,
          trade_originality: 'manual_pending_review',
          magic_number: 0,
          profit: 100.0
        )
      end

      it 'handles rapid classification changes' do
        trade.update!(trade_originality: 'manual_client', is_unauthorized_manual: true)
        trade.update!(trade_originality: 'manual_admin', is_unauthorized_manual: false)
        trade.update!(trade_originality: 'manual_client', is_unauthorized_manual: true)
        
        expect(trade.reload.trade_originality).to eq('manual_client')
        expect(trade.is_unauthorized_manual).to be true
      end
    end
  end
end

