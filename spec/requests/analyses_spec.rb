require "rails_helper"

# #25 分析シート: 残食率が高い上位5品（5-A）
RSpec.describe "分析シート", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  # dish を1品目にした献立を作る。excluded: true で集計対象外の日にする
  def serve(dish, date, portion: 20, leftovers: nil, excluded: false)
    menu = user.menus.build(date_provided: date, excluded_from_stats: excluded,
                            exclusion_reason: ("学級閉鎖" if excluded))
    menu.menu_items.build(dish: dish, portion_size: portion, weight_of_leftovers: leftovers)
    menu.tap(&:save!)
  end

  def dish_named(name)
    create(:dish, user: user, name: name)
  end

  it "ログインしていないとログイン画面へ移る" do
    get analysis_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "残食率が高い上位5品" do
    # 「今年度」がテストを流す日で変わらないよう、今日を 2026-09-26 に固定する
    around { |example| travel_to(Time.zone.local(2026, 9, 26)) { example.run } }
    before { sign_in user }

    it "残食率の高い順に並ぶ" do
      serve(dish_named("コールスロー"), Date.new(2026, 9, 1), leftovers: 2)   # 10.0%
      serve(dish_named("ひじきの煮物"), Date.new(2026, 9, 2), leftovers: 6)   # 30.0%
      serve(dish_named("海藻サラダ"), Date.new(2026, 9, 3), leftovers: 4)     # 20.0%
      get analysis_path
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body.index("ひじきの煮物")).to be < body.index("海藻サラダ")
      expect(body.index("海藻サラダ")).to be < body.index("コールスロー")
    end

    it "5品までしか出ない（6番目は出ない）" do
      (1..6).each do |n|
        serve(dish_named("料理#{n}"), Date.new(2026, 9, n), leftovers: n)   # 料理1 がいちばん低い
      end
      get analysis_path
      expect(response.body).to include("料理6", "料理2")
      expect(response.body).not_to include("料理1<")
    end

    it "率は「合計残食量 ÷ 合計提供量」で出す（1回ごとの率の平均ではない）" do
      dish = dish_named("ひじきの煮物")
      serve(dish, Date.new(2026, 9, 1), portion: 10, leftovers: 5)   # 50%
      serve(dish, Date.new(2026, 9, 2), portion: 30, leftovers: 3)   # 10%
      get analysis_path
      # 合計 8 ÷ 40 = 20.0%（平均だと 30.0% になる）
      expect(response.body).to include("20.0%")
      expect(response.body).not_to include("30.0%")
    end

    it "提供回数が出る" do
      dish = dish_named("ひじきの煮物")
      serve(dish, Date.new(2026, 9, 1), leftovers: 2)
      serve(dish, Date.new(2026, 9, 2), leftovers: 4)
      get analysis_path
      expect(response.body).to include("（提供2回）")
    end

    it "料理名から料理詳細へ移れる" do
      dish = dish_named("ひじきの煮物")
      serve(dish, Date.new(2026, 9, 1), leftovers: 2)
      get analysis_path
      expect(response.body).to include(dish_path(dish))
    end

    it "集計対象外の日は含めない" do
      serve(dish_named("ひじきの煮物"), Date.new(2026, 9, 1), leftovers: 6, excluded: true)
      get analysis_path
      expect(response.body).not_to include("ひじきの煮物")
    end

    it "残食が未入力の品目は含めない" do
      serve(dish_named("ひじきの煮物"), Date.new(2026, 9, 1))
      get analysis_path
      expect(response.body).not_to include("ひじきの煮物")
    end

    it "削除した料理は出ない" do
      dish = dish_named("ひじきの煮物")
      serve(dish, Date.new(2026, 9, 1), leftovers: 6)
      dish.update!(deleted_at: Time.current)
      get analysis_path
      expect(response.body).not_to include("ひじきの煮物")
    end

    it "他のユーザーの料理は出ない" do
      other = create(:user)
      other_dish = create(:dish, user: other, name: "よその学校のカレー")
      menu = other.menus.build(date_provided: Date.new(2026, 9, 1))
      menu.menu_items.build(dish: other_dish, portion_size: 20, weight_of_leftovers: 10)
      menu.save!
      get analysis_path
      expect(response.body).not_to include("よその学校のカレー")
    end

    it "記録が無いときはメッセージが出る" do
      get analysis_path
      expect(response.body).to include("今年度の記録がまだありません。")
    end
  end

  describe "年度の区切り（4/1〜3/31）" do
    before do
      sign_in user
      serve(dish_named("前年度の料理"), Date.new(2026, 3, 31), leftovers: 2)
      serve(dish_named("今年度の料理"), Date.new(2026, 4, 1), leftovers: 2)
    end

    it "3/31 に開くと、その前の 4/1 からの記録だけが入る" do
      travel_to(Time.zone.local(2027, 3, 31)) { get analysis_path }
      expect(response.body).to include("今年度の料理")
      expect(response.body).not_to include("前年度の料理")
    end

    it "4/1 に開くと、新しい年度になり前の年度の記録は入らない" do
      travel_to(Time.zone.local(2027, 4, 1)) { get analysis_path }
      expect(response.body).not_to include("今年度の料理")
      expect(response.body).to include("今年度の記録がまだありません。")
    end

    it "1〜3月に開いても、前の年の 4/1 から数える" do
      travel_to(Time.zone.local(2027, 1, 15)) { get analysis_path }
      expect(response.body).to include("今年度の料理")
    end
  end
end
