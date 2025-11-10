FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    commission_rate { 10.0 }
    is_admin { false }
    init_mt5 { false }

    trait :admin do
      is_admin { true }
    end

    trait :with_mt5_token do
      mt5_api_token { SecureRandom.hex(16) }
      init_mt5 { true }
    end

    trait :with_accounts do
      after(:create) do |user|
        create_list(:mt5_account, 2, user: user)
      end
    end
  end
end

