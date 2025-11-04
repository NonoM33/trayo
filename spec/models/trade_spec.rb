require 'rails_helper'

RSpec.describe Trade, type: :model do
  describe 'associations' do
    it { should belong_to(:mt5_account) }
  end

  describe 'validations' do
    it { should validate_presence_of(:trade_id) }
    it { should validate_uniqueness_of(:trade_id).scoped_to(:mt5_account_id) }
  end

  describe 'scopes' do
    let(:account) { create(:mt5_account) }
    let!(:closed_trade) { create(:trade, mt5_account: account, status: 'closed') }
    let!(:open_trade) { create(:trade, :open, mt5_account: account) }

    it 'returns closed trades' do
      expect(Trade.closed).to include(closed_trade)
      expect(Trade.closed).not_to include(open_trade)
    end
  end

  describe '#bot_name' do
    let(:account) { create(:mt5_account) }
    let(:bot) { create(:trading_bot, magic_number_prefix: 12345) }
    let(:trade) { create(:trade, mt5_account: account, magic_number: 12345) }

    it 'returns bot name when magic number matches' do
      expect(trade.bot_name).to eq(bot.name)
    end

    it 'returns nil when no magic number' do
      trade.update(magic_number: nil)
      expect(trade.bot_name).to be_nil
    end
  end

  describe '#gross_profit' do
    let(:trade) { create(:trade, profit: 100.0, commission: -5.0, swap: 2.0) }

    it 'calculates gross profit correctly' do
      expect(trade.gross_profit).to eq(97.0)
    end
  end

  describe 'callbacks' do
    let(:account) { create(:mt5_account) }

    it 'broadcasts trade created after create' do
      trade = build(:trade, mt5_account: account)
      expect(TradeChannel).to receive(:broadcast_created).with(trade)
      trade.save
    end

    it 'broadcasts trade updated after update' do
      trade = create(:trade, mt5_account: account)
      expect(TradeChannel).to receive(:broadcast_updated).with(trade)
      trade.update(profit: 200.0)
    end
  end
end

