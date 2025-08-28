FactoryBot.define do
  factory :user do
    name { "MyString" }
    email { "MyString" }
    role { 1 }
    department { nil }
    manager { nil }
  end
end
