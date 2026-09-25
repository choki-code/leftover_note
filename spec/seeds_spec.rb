require "rails_helper"

# 6-A デモデータは何度実行しても同じ状態になる（冪等）
RSpec.describe "db/seeds.rb" do
  it "2回実行しても、ユーザー・料理・献立が増えない" do
    Rails.application.load_seed
    counts = [ User.count, Dish.count, Menu.count, MenuItem.count ]

    Rails.application.load_seed
    expect([ User.count, Dish.count, Menu.count, MenuItem.count ]).to eq(counts)
  end

  it "給食実施日が10日あり、対象外の日が1日ある" do
    Rails.application.load_seed
    demo = User.find_by!(email: "demo@example.com")
    expect(demo.menus.count).to eq(10)
    expect(demo.menus.where(excluded_from_stats: true).count).to eq(1)
  end
end
