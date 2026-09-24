require "rails_helper"

# #22 献立フォームの各行に、料理の履歴（#21）へのリンクの仕掛けがある（3-I）
# 選んだ瞬間に出る動き（JS）はブラウザで確かめる。ここでは HTML の形だけを見る
RSpec.describe "献立フォームの履歴リンク", type: :request do
  let(:user) { create(:user) }
  let!(:dish) { create(:dish, user: user, name: "ひじきの煮物") }

  before { sign_in user }

  it "新規登録フォームの各行に、隠れた履歴リンクと dish-history コントローラがある" do
    get new_menu_path
    assert_select "tr[data-controller='dish-history'][data-dish-history-url-value=?]", dishes_path, count: 5
    assert_select "tr[data-controller='dish-history'] a[data-dish-history-target='link'][hidden]", count: 5
  end

  it "料理の select が変わると update が呼ばれる" do
    get new_menu_path
    assert_select "select[data-action='change->dish-history#update'][data-dish-history-target='select']", count: 5
  end

  it "履歴リンクは同じタブで開く（target を付けない）" do
    get new_menu_path
    assert_select "a[data-dish-history-target='link'][target]", count: 0
  end

  it "編集フォームにも同じ仕掛けがある" do
    menu = user.menus.build(date_provided: Date.new(2026, 9, 24))
    menu.menu_items.build(dish: dish, portion_size: 20)
    menu.save!
    get edit_menu_path(menu)
    assert_select "tr[data-controller='dish-history'] a[data-dish-history-target='link']", minimum: 1
  end
end
