require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:mt5_accounts).dependent(:destroy) }
    it { should have_many(:trades).through(:mt5_accounts) }
    it { should have_many(:payments).dependent(:destroy) }
    it { should have_many(:credits).dependent(:destroy) }
    it { should have_many(:bot_purchases).dependent(:destroy) }
    it { should have_many(:vps).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:password).is_at_least(6) }
    it { should validate_numericality_of(:commission_rate).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
  end

  describe 'scopes' do
    let!(:admin_user) { create(:user, :admin) }
    let!(:client_user) { create(:user) }

    it 'returns admins' do
      expect(User.admins).to include(admin_user)
      expect(User.admins).not_to include(client_user)
    end

    it 'returns clients' do
      expect(User.clients).to include(client_user)
      expect(User.clients).not_to include(admin_user)
    end
  end

  describe 'callbacks' do
    it 'generates mt5_api_token before create' do
      user = build(:user)
      expect(user.mt5_api_token).to be_nil
      user.save
      expect(user.mt5_api_token).to be_present
    end
  end

  describe '#total_profits' do
    let(:user) { create(:user, :with_accounts) }
    let(:account1) { user.mt5_accounts.first }
    let(:account2) { user.mt5_accounts.second }

    before do
      create(:trade, mt5_account: account1, profit: 100.0)
      create(:trade, mt5_account: account2, profit: 200.0)
    end

    it 'returns the sum of net gains from all accounts' do
      expect(user.total_profits).to be > 0
    end
  end

  describe '#balance_due' do
    let(:user) { create(:user) }

    before do
      create(:payment, user: user, amount: 1000.0, status: 'validated')
      create(:credit, user: user, amount: 200.0)
    end

    it 'calculates balance due correctly' do
      expect(user.balance_due).to be_a(Numeric)
    end
  end
end

