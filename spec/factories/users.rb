FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "nutritionist#{n}@example.com" }
    password { "password" }
    # #12 で users に NOT NULL の3列が入ったので、factory でも必ず埋める
    school_name { "ひまわり小学校" }
    academic_year { "2026" }
    current_enrollment { 320 }
  end
end
