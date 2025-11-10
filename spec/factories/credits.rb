FactoryBot.define do
  factory :credit do
    association :user
    amount { 100.0 }
    reason { "Promotional credit" }
  end
end

