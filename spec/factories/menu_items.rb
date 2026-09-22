FactoryBot.define do
  factory :menu_item do
    menu
    dish
    portion_size { 20.0 }
    weight_of_leftovers { nil }
  end
end
