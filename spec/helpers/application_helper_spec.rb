require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:user) { create(:user) }

  describe "#error_summary" do
    it "エラーが無ければ何も出さない" do
      expect(helper.error_summary(user.dishes.new)).to be_nil
    end

    it "nil を渡しても落ちない" do
      expect(helper.error_summary(nil)).to be_nil
    end

    it "エラーの件数と中身を日本語で出す" do
      dish = user.dishes.new(name: "", category: "main_dish")
      dish.valid?

      html = helper.error_summary(dish)

      expect(html).to include("入力に1件の誤りがあります")
      expect(html).to include("料理名を入力してください")
    end

    it "2件以上なら複数形の文言になる" do
      dish = user.dishes.new(name: "", category: "drink")
      dish.valid?

      expect(helper.error_summary(dish)).to include("入力に2件の誤りがあります")
    end
  end
end
