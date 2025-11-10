FactoryBot.define do
  factory :trade do
    association :mt5_account
    sequence(:trade_id) { |n| "TRADE#{n}" }
    symbol { "EURUSD" }
    trade_type { "buy" }
    volume { 0.1 }
    open_price { 1.1000 }
    close_price { 1.1050 }
    profit { 50.0 }
    commission { -0.5 }
    swap { 0.0 }
    open_time { 1.hour.ago }
    close_time { Time.current }
    status { "closed" }
    magic_number { nil }
    comment { nil }
    trade_originality { "bot" }
    is_unauthorized_manual { false }

    trait :winning do
      profit { 100.0 }
      close_price { 1.1100 }
    end

    trait :losing do
      profit { -50.0 }
      close_price { 1.0950 }
    end

    trait :open do
      status { "open" }
      close_price { nil }
      close_time { nil }
    end

    trait :with_bot do
      magic_number { 12345 }
    end

    trait :manual_admin do
      trade_originality { "manual_admin" }
      magic_number { nil }
    end

    trait :manual_client do
      trade_originality { "manual_client" }
      magic_number { nil }
    end
  end
end

