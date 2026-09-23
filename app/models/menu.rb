class Menu < ApplicationRecord
  belongs_to :user
  has_many :menu_items, dependent: :destroy
  accepts_nested_attributes_for :menu_items, reject_if: :all_blank
  has_many :dishes, through: :menu_items

  scope :for_stats, -> { where(excluded_from_stats: false) }
  scope :recent_first, -> { order(date_provided: :desc) }

  validates :date_provided, presence: true

  validates :date_provided, uniqueness: { scope: :user_id, message: "はすでに登録されています（同じ日の献立は1件だけです）" }
  validates :attendance_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :exclusion_reason, presence: true, if: :excluded_from_stats?
  validate :must_have_at_least_one_item
  validate :dish_must_not_be_duplicated

  private

  # 同じ料理を2回選ぶと DB の UNIQUE で落ちるので、その前に画面へ返す
  def dish_must_not_be_duplicated
    dish_ids = menu_items.reject(&:marked_for_destruction?).filter_map(&:dish_id)
    duplicated = dish_ids.tally.select { |_id, count| count > 1 }.keys
    return if duplicated.empty?

    names = Dish.where(id: duplicated).pluck(:name)
    errors.add(:base, "同じ料理を2回選んでいます（#{names.join('、')}）。1行にまとめてください")
  end

  # 「献立には料理が1品以上」は DB では表せないのでここで
  def must_have_at_least_one_item
    remaining = menu_items.reject(&:marked_for_destruction?)
    errors.add(:base, "献立には料理を1品以上登録してください") if remaining.empty?
  end
end
