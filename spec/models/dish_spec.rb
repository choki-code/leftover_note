require "rails_helper"

# #14 料理の論理削除（2-D / 2-E / 2-F）の仕様。
# 消せない理由の文言は仮置き。実装で文言を変えたら、ここの reason も合わせてよい
RSpec.describe Dish, type: :model do
  let(:reason) { "献立の記録に使われているため削除できません" }

  let(:user) { create(:user) }
  let(:dish) { create(:dish, user: user, name: "カレー") }

  # 料理を献立に1回使う（= menu_items に記録が紐づいた状態を作る）
  def use_in_menu(dish)
    menu = user.menus.build(date_provided: Date.new(2026, 9, 14))
    menu.menu_items.build(dish: dish, portion_size: 20.0)
    menu.save!
  end

  describe "#soft_delete" do
    context "献立で使われていない料理" do
      # 行は消さず deleted_at を入れるだけ。過去の記録から料理名を引けるようにするため（2-F）
      it "true を返し、deleted_at が入る" do
        expect(dish.soft_delete).to be true
        expect(dish.reload.deleted_at).to be_present
      end

      it "alive から消えるが、行は残る" do
        dish.soft_delete
        expect(Dish.alive).not_to include(dish)
        expect(Dish.exists?(dish.id)).to be true
      end
    end

    context "献立で使われている料理" do
      before { use_in_menu(dish) }

      # 例外ではなく false + errors で返す。コントローラが確認画面に理由を出せるようにするため
      it "false を返し、deleted_at は入らない" do
        expect(dish.soft_delete).to be false
        expect(dish.reload.deleted_at).to be_nil
      end

      it "errors[:base] に消せない理由が入る" do
        dish.soft_delete
        expect(dish.errors[:base]).to include(a_string_including(reason))
      end
    end
  end

  describe "#deletable?" do
    it "献立で使われていなければ true" do
      expect(dish.deletable?).to be true
    end

    # 確認画面を開いた時点で「消せない」と分かるようにするため（削除ボタンを押す前に）
    it "献立で使われていれば false" do
      use_in_menu(dish)
      expect(dish.deletable?).to be false
    end
  end

  describe "削除済みの名前の再登録（2-E）" do
    # model の uniqueness（conditions: deleted_at nil）と DB の部分インデックスの両方を通ることを確かめる
    it "論理削除した料理と同じ名前で登録できる" do
      dish.soft_delete
      again = user.dishes.build(name: "カレー", category: "main_dish")
      expect(again).to be_valid
      expect { again.save! }.not_to raise_error
    end

    # 回帰: 削除していない同名は今まで通り弾く
    it "生きている料理と同じ名前は登録できない" do
      dish
      again = user.dishes.build(name: "カレー", category: "main_dish")
      expect(again).not_to be_valid
    end
  end
end
