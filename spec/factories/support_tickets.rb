FactoryBot.define do
  factory :support_ticket do
    user { nil }
    phone_number { "MyString" }
    status { "MyString" }
    ticket_number { "MyString" }
    subject { "MyText" }
    description { "MyText" }
    sms_message_id { "MyString" }
    created_via { "MyString" }
  end
end
