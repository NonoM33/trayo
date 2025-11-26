FactoryBot.define do
  factory :mt5_account do
    association :user
    sequence(:mt5_id) { |n| "123456#{n}" }
    account_name { Faker::Company.name }
    balance { 10000.0 }
    initial_balance { 10000.0 }
    high_watermark { 10000.0 }
    total_withdrawals { 0.0 }
    total_deposits { 0.0 }
    broker_name { Faker::Company.name }
    broker_server { "DemoServer" }
    last_sync_at { Time.current }

    trait :with_trades do
      after(:create) do |account|
        create_list(:trade, 5, mt5_account: account)
      end
    end

    trait :with_profits do
      balance { 15000.0 }
      high_watermark { 15000.0 }
    end
  end
end

