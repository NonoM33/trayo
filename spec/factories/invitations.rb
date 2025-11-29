FactoryBot.define do
  factory :invitation do
    sequence(:code) { |n| "INV#{n}#{SecureRandom.hex(8).upcase}" }
    sequence(:email) { |n| "invite#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { Faker::PhoneNumber.phone_number }
    status { "pending" }
    expires_at { 7.days.from_now }
    
    trait :with_broker_data do
      broker_data { { broker_name: "IC Markets", account_id: "123456789", account_password: "testpass123" }.to_json }
      broker_credentials { { account_id: "123456789", account_password: "testpass123" }.to_json }
    end
    
    trait :with_bots do
      transient do
        bots { [] }
      end
      
      after(:build) do |invitation, evaluator|
        if evaluator.bots.any?
          invitation.selected_bots = evaluator.bots.map(&:id).to_json
        end
      end
    end
    
    trait :with_subscription do
      after(:build) do |invitation|
        invitation.broker_data = (JSON.parse(invitation.broker_data || "{}").merge(
          offer_type: "subscription",
          subscription_plan: "pro"
        )).to_json
      end
    end
    
    trait :completed do
      status { "completed" }
    end
    
    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end

