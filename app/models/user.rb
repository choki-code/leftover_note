class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :dishes, dependent: :destroy
  has_many :menus, dependent: :destroy

  validates :school_name, presence: true, length: { maximum: 100 }
  validates :academic_year, presence: true, length: { maximum: 10 }
  validates :current_enrollment, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 }

  def heading_label
    "#{school_name} #{academic_year}年度（全校児童数 #{current_enrollment}人）"
  end
end
