FactoryBot.define do
  factory :trading_bot do
    sequence(:name) { |n| "Bot #{n}" }
    description { Faker::Lorem.paragraph }
    price { 999.99 }
    status { "active" }
    is_active { true }
    risk_level { "medium" }
    magic_number_prefix { 10000 }
    max_drawdown_limit { 10.0 }
    projection_monthly_min { 500.0 }
    projection_monthly_max { 2000.0 }
    projection_yearly { 12000.0 }
    win_rate { 65.0 }
    features { { "scalping" => true, "hedging" => false } }

    trait :inactive do
      status { "inactive" }
      is_active { false }
    end

    trait :low_risk do
      risk_level { "low" }
      max_drawdown_limit { 5.0 }
    end

    trait :high_risk do
      risk_level { "high" }
      max_drawdown_limit { 20.0 }
    end
  end
end

