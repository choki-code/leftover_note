FactoryBot.define do
  factory :dish do
    user
    sequence(:name) { |n| "料理#{n}" }
    category { "main_dish" }
  end
end
