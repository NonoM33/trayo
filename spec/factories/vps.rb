FactoryBot.define do
  factory :vps do
    association :user
    sequence(:name) { |n| "VPS #{n}" }
    server_location { "Paris" }
    status { "active" }
    monthly_price { 39.99 }
    renewal_date { 1.year.from_now }
    ip_address { Faker::Internet.ip_v4_address }
    username { Faker::Internet.username }
    password { SecureRandom.hex(8) }
    ordered_at { 1.month.ago }
    configured_at { 1.month.ago }
    ready_at { 1.month.ago }
    activated_at { 1.month.ago }

    trait :ordered do
      status { "ordered" }
      configured_at { nil }
      ready_at { nil }
      activated_at { nil }
    end

    trait :configuring do
      status { "configuring" }
      configured_at { Time.current }
      ready_at { nil }
      activated_at { nil }
    end

    trait :ready do
      status { "ready" }
      ready_at { Time.current }
      activated_at { nil }
    end
  end
end

