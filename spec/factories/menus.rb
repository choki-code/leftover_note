FactoryBot.define do
  factory :menu do
    user
    sequence(:date_provided) { |n| Date.new(2026, 9, 1) + n.days }

    # 献立は「1品以上」が必須なので、既定で1品つける。
    # 品目を自分で組みたいテストでは menu_items を上書きする
    after(:build) do |menu|
      menu.menu_items << build(:menu_item, menu: menu, dish: build(:dish, user: menu.user)) if menu.menu_items.empty?
    end
  end
end
