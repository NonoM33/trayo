FactoryBot.define do
  factory :payment do
    association :user
    amount { 1000.0 }
    status { "pending" }
    payment_date { Time.current }
    description { "Payment for commission" }
    payment_method { "bank_transfer" }

    trait :validated do
      status { "validated" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end

