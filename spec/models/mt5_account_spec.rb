require 'rails_helper'

RSpec.describe Mt5Account, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:trades).dependent(:destroy) }
    it { should have_many(:withdrawals).dependent(:destroy) }
    it { should have_many(:deposits).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:mt5_id) }
    it { should validate_uniqueness_of(:mt5_id) }
    it { should validate_presence_of(:account_name) }
    it { should validate_presence_of(:balance) }
    it { should validate_numericality_of(:balance) }
  end

  describe '#net_gains' do
    let(:account) { create(:mt5_account, balance: 12000.0, initial_balance: 10000.0, total_withdrawals: 500.0) }

    it 'calculates net gains correctly' do
      expect(account.net_gains).to eq(2500.0)
    end
  end

  describe '#real_gains' do
    let(:account) { create(:mt5_account, balance: 12000.0, initial_balance: 10000.0) }

    it 'calculates real gains correctly' do
      expect(account.real_gains).to eq(2000.0)
    end
  end

  describe '#commissionable_gains' do
    let(:account) { create(:mt5_account, :with_trades) }

    before do
      account.trades.update_all(trade_originality: 'bot')
    end

    it 'calculates commissionable gains' do
      expect(account.commissionable_gains).to be_a(Numeric)
    end
  end

  describe '#calculate_projection' do
    let(:account) { create(:mt5_account, balance: 10000.0) }

    before do
      create_list(:trade, 10, mt5_account: account, profit: 50.0, close_time: 1.day.ago)
    end

    it 'returns projection data' do
      projection = account.calculate_projection(30)
      expect(projection).to have_key(:projected_balance)
      expect(projection).to have_key(:daily_average)
      expect(projection).to have_key(:confidence)
    end
  end

  describe 'callbacks' do
    let(:account) { create(:mt5_account) }

    it 'broadcasts balance update after save' do
      expect(AccountChannel).to receive(:broadcast_update).with(account)
      account.update(balance: 11000.0)
    end
  end
end

