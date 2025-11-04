FactoryBot.define do
  factory :deposit do
    association :mt5_account
    amount { 1000.0 }
    deposit_date { Time.current }
    transaction_id { SecureRandom.hex(8) }
    notes { "Deposit" }
  end
end

