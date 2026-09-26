class MenuItem < ApplicationRecord
  belongs_to :menu
  belongs_to :dish

  HIGH_RATE_THRESHOLD = 0.30
  MIDDLE_RATE_THRESHOLD = 0.15

  validates :portion_size, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :weight_of_leftovers, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :dish_id, uniqueness: { scope: :menu_id, message: "は同じ日の献立で重複しています" }
  validate :leftovers_within_portion
  validate :dish_belongs_to_same_user

  def leftover_rate
    return nil if weight_of_leftovers.blank? || portion_size.to_f.zero?

    weight_of_leftovers.to_f / portion_size.to_f
  end

  # 3-F 高い品を色で強調するための区分
  def rate_level
    rate = leftover_rate
    return :unrecorded if rate.nil?
    return :high if rate >= HIGH_RATE_THRESHOLD
    return :middle if rate >= MIDDLE_RATE_THRESHOLD

    :low
  end

  # 5-B この料理の前回（この記録より前で、集計対象の日）の記録
  def previous_record
    return nil if dish_id.blank?

    MenuItem.joins(:menu)
            .merge(Menu.for_stats)
            .where(dish_id: dish_id, menus: { user_id: menu&.user_id })
            .where.not(id: id)
            .where(menus: { date_provided: ...menu&.date_provided })
            .where.not(weight_of_leftovers: nil)
            .order("menus.date_provided DESC")
            .first
  end

  # 5-A 残食率が高い料理（合計残食量 ÷ 合計提供量）。
  # 集計対象外の日・残食が未入力の品目・削除した料理は含めない
  def self.ranking_for(user, period, limit: 5)
    joins(:menu, :dish)
      .merge(Menu.for_stats)
      .merge(Dish.alive)
      .where(menus: { user_id: user.id, date_provided: period })
      .where.not(weight_of_leftovers: nil)
      .group("menu_items.dish_id", "dishes.name")
      .select("menu_items.dish_id",
              "dishes.name AS dish_name",
              "COUNT(*) AS served_count",
              "SUM(menu_items.weight_of_leftovers) / SUM(menu_items.portion_size) AS rate")
      .order("rate DESC", "dishes.name")
      .limit(limit)
  end
  # 年度（4/1〜3/31）。日付を3か月前にずらすと、その年が年度になる
  # 例: 2027-03-31 → 2026-12-31 → 2026年度 / 2027-04-01 → 2027-01-01 → 2027年度
  FISCAL_YEAR_SQL = "CAST(EXTRACT(YEAR FROM menus.date_provided - INTERVAL '3 months') AS integer)".freeze

  # #59 年度ごとの平均残食率（合計残食量 ÷ 合計提供量）。
  # 集計対象外の日・残食が未入力の品目は含めない。
  # 削除した料理は含める（一度報告した年度の数字が、料理の削除で変わらないように）
  def self.yearly_rates_for(user)
    joins(:menu)
      .merge(Menu.for_stats)
      .where(menus: { user_id: user.id })
      .where.not(weight_of_leftovers: nil)
      .group(FISCAL_YEAR_SQL)
      .select("#{FISCAL_YEAR_SQL} AS fiscal_year",
              "SUM(menu_items.weight_of_leftovers) / SUM(menu_items.portion_size) AS rate")
      .order("fiscal_year")
  end

  private

  # 他人の料理 id をフォームに差し込まれても弾く。
  # Strong Parameters は「dish_id を受け取っていいか」しか見ず、中身が誰のものかは見ない
  def dish_belongs_to_same_user
    return if dish.nil? || menu.nil? || menu.user_id.nil?

    errors.add(:dish_id, "は選択できません") if dish.user_id != menu.user_id
  end

  # 4-D 残食量が提供量を超える入力はエラー
  def leftovers_within_portion
    return if weight_of_leftovers.blank? || portion_size.blank?

    if weight_of_leftovers.to_f > portion_size.to_f
      errors.add(:weight_of_leftovers, "は提供量（#{portion_size.to_f.round(2)}kg）を超えられません")
    end
  end
end
