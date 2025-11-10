FactoryBot.define do
  factory :withdrawal do
    association :mt5_account
    amount { 500.0 }
    withdrawal_date { Time.current }
    transaction_id { SecureRandom.hex(8) }
    notes { "Withdrawal request" }
  end
end

