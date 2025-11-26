FactoryBot.define do
  factory :ticket_comment do
    support_ticket { nil }
    user { nil }
    content { "MyText" }
    is_internal { false }
  end
end
