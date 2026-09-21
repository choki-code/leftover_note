FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "nutritionist#{n}@example.com" }
    password { "password" }
  end
end
