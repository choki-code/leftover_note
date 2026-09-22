require "rails_helper"

RSpec.describe MenuItem, type: :model do
  let(:user) { create(:user) }
  let(:menu) { create(:menu, user: user) }
  let(:dish) { create(:dish, user: user) }

  def build_item(attrs = {})
    menu.menu_items.build({ dish: dish, portion_size: 20.0 }.merge(attrs))
  end

  describe "提供量" do
    it "無ければ保存できない" do
      expect(build_item({ portion_size: nil })).not_to be_valid
    end

    it "0 は通らない" do
      expect(build_item({ portion_size: 0 })).not_to be_valid
    end

    it "100kg までは通る" do
      expect(build_item({ portion_size: 100 })).to be_valid
    end

    it "100kg を超えると通らない" do
      expect(build_item({ portion_size: 100.01 })).not_to be_valid
    end
  end

  describe "残食量" do
    it "空でも保存できる（4-C 給食後に入力する）" do
      expect(build_item({ weight_of_leftovers: nil })).to be_valid
    end

    it "0 は通る（完食）" do
      expect(build_item({ weight_of_leftovers: 0 })).to be_valid
    end

    it "負の数は通らない" do
      expect(build_item({ weight_of_leftovers: -0.1 })).not_to be_valid
    end

    it "提供量と同じなら通る（まったく食べられなかった日）" do
      expect(build_item({ portion_size: 20.0, weight_of_leftovers: 20.0 })).to be_valid
    end

    it "提供量を超えると通らない（4-D）" do
      item = build_item({ portion_size: 20.0, weight_of_leftovers: 20.01 })

      expect(item).not_to be_valid
      expect(item.errors.full_messages.join).to include("提供量（20.0kg）を超えられません")
    end
  end

  describe "#leftover_rate（4-B）" do
    it "残った量 ÷ 出した量" do
      expect(build_item({ portion_size: 20.0, weight_of_leftovers: 3.0 }).leftover_rate).to eq(0.15)
    end

    it "完食なら 0" do
      expect(build_item({ weight_of_leftovers: 0 }).leftover_rate).to eq(0)
    end

    it "未入力なら nil（0 ではない）" do
      expect(build_item({ weight_of_leftovers: nil }).leftover_rate).to be_nil
    end
  end

  describe "#rate_level（3-F の色分け）" do
    it "30% 以上は :high" do
      expect(build_item({ portion_size: 10.0, weight_of_leftovers: 3.0 }).rate_level).to eq(:high)
    end

    it "15% 以上 30% 未満は :middle" do
      expect(build_item({ portion_size: 10.0, weight_of_leftovers: 1.5 }).rate_level).to eq(:middle)
    end

    it "15% 未満は :low" do
      expect(build_item({ portion_size: 10.0, weight_of_leftovers: 1.49 }).rate_level).to eq(:low)
    end

    it "未入力は :unrecorded" do
      expect(build_item({ weight_of_leftovers: nil }).rate_level).to eq(:unrecorded)
    end
  end

  describe "同じ献立での重複" do
    it "同じ料理を2行は作れない" do
      menu.menu_items.create!(dish: dish, portion_size: 10.0)
      expect(build_item).not_to be_valid
    end

    it "別の料理なら作れる" do
      menu.menu_items.create!(dish: dish, portion_size: 10.0)
      expect(build_item({ dish: create(:dish, user: user) })).to be_valid
    end
  end

  describe "他人の料理を差し込まれたとき（認可）" do
    it "弾く" do
      others_dish = create(:dish, user: create(:user))
      item = build_item({ dish: others_dish })

      expect(item).not_to be_valid
      expect(item.errors[:dish_id]).to include("は選択できません")
    end

    it "DB にも入らない" do
      others_dish = create(:dish, user: create(:user))

      expect {
        menu.menu_items.create!(dish: others_dish, portion_size: 10.0)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
