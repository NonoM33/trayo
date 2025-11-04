FactoryBot.define do
  factory :bot_purchase do
    association :user
    association :trading_bot
    price_paid { trading_bot.price }
    status { "active" }
    is_running { false }
    magic_number { trading_bot.magic_number_prefix ? trading_bot.magic_number_prefix + user.id : nil }
    total_profit { 0.0 }
    trades_count { 0 }
    current_drawdown { 0.0 }
    max_drawdown_recorded { 0.0 }

    trait :running do
      is_running { true }
      started_at { 1.day.ago }
    end

    trait :stopped do
      is_running { false }
      stopped_at { Time.current }
    end

    trait :with_profit do
      total_profit { 500.0 }
      trades_count { 10 }
    end

    trait :with_drawdown do
      current_drawdown { 5.0 }
      max_drawdown_recorded { 8.0 }
    end
  end
end

