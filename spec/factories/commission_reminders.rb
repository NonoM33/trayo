FactoryBot.define do
  factory :commission_reminder do
    association :user
    kind { "initial" }
    amount { 100.50 }
    watermark_reference { 1000.00 }
    phone_number { "+33776695886" }
    status { "sent" }
    deadline_at { 48.hours.from_now }
    sent_at { Time.current }
    message_content { "Test SMS message" }

    trait :pending do
      status { "pending" }
      sent_at { nil }
    end

    trait :sent do
      status { "sent" }
      sent_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      error_message { "Test error" }
    end

    trait :initial do
      kind { "initial" }
    end

    trait :follow_up_24h do
      kind { "follow_up_24h" }
    end

    trait :follow_up_2h do
      kind { "follow_up_2h" }
    end

    trait :follow_up_28d do
      kind { "follow_up_28d" }
    end

    trait :manual do
      kind { "manual" }
    end
  end
end

