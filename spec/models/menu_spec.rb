require "rails_helper"

RSpec.describe Menu, type: :model do
  let(:user) { create(:user) }

  def build_menu(attrs = {}, dishes: 1)
    menu = user.menus.build({ date_provided: Date.new(2026, 9, 14) }.merge(attrs))
    dishes.times { menu.menu_items.build(dish: create(:dish, user: user), portion_size: 20.0) }
    menu
  end

  describe "提供日" do
    it "無ければ保存できない" do
      menu = build_menu({ date_provided: nil })
      expect(menu).not_to be_valid
      expect(menu.errors[:date_provided]).to be_present
    end

    it "同じ日を2件は登録できない（3-B）" do
      build_menu.save!
      second = build_menu
      expect(second).not_to be_valid
      expect(second.errors.full_messages.join).to include("同じ日の献立は1件だけです")
    end

    it "別のユーザーなら同じ日を登録できる" do
      build_menu.save!
      other = create(:user)
      other_menu = other.menus.build(date_provided: Date.new(2026, 9, 14))
      other_menu.menu_items.build(dish: create(:dish, user: other), portion_size: 20.0)
      expect(other_menu).to be_valid
    end
  end

  describe "品目" do
    it "1品も無ければ保存できない" do
      menu = build_menu({}, dishes: 0)
      expect(menu).not_to be_valid
      expect(menu.errors.full_messages.join).to include("1品以上")
    end

    it "同じ料理を2回選べない" do
      dish = create(:dish, user: user, name: "カレー")
      menu = user.menus.build(date_provided: Date.new(2026, 9, 14))
      2.times { menu.menu_items.build(dish: dish, portion_size: 10.0) }

      expect(menu).not_to be_valid
      expect(menu.errors.full_messages.join).to include("同じ料理を2回選んでいます")
      expect(menu.errors.full_messages.join).to include("カレー")
    end
  end

  describe "実食数" do
    it "0 以上の整数なら通る" do
      expect(build_menu({ attendance_count: 0 })).to be_valid
    end

    it "空でも通る（任意）" do
      expect(build_menu({ attendance_count: nil })).to be_valid
    end

    it "負の数は通らない" do
      expect(build_menu({ attendance_count: -1 })).not_to be_valid
    end

    it "小数は通らない" do
      expect(build_menu({ attendance_count: 1.5 })).not_to be_valid
    end
  end

  describe "集計対象外（3-G）" do
    it "除外するなら理由が要る" do
      menu = build_menu({ excluded_from_stats: true, exclusion_reason: nil })
      expect(menu).not_to be_valid
      expect(menu.errors[:exclusion_reason]).to be_present
    end

    it "理由があれば通る" do
      expect(build_menu({ excluded_from_stats: true, exclusion_reason: "学級閉鎖" })).to be_valid
    end

    it "除外しないなら理由は要らない" do
      expect(build_menu({ excluded_from_stats: false, exclusion_reason: nil })).to be_valid
    end
  end

  describe "スコープ" do
    it "for_stats は除外した日を含まない（5-C）" do
      kept = build_menu.tap(&:save!)
      build_menu({ date_provided: Date.new(2026, 9, 15), excluded_from_stats: true, exclusion_reason: "学級閉鎖" }).save!

      expect(Menu.for_stats).to eq([ kept ])
    end

    it "recent_first は日付の新しい順（3-C）" do
      old = build_menu({ date_provided: Date.new(2026, 9, 1) }).tap(&:save!)
      recent = build_menu({ date_provided: Date.new(2026, 9, 30) }).tap(&:save!)

      expect(Menu.recent_first.to_a).to eq([ recent, old ])
    end
  end
end
