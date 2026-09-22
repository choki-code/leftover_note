class MakeSchoolProfileRequired < ActiveRecord::Migration[8.1]
  def change
    # 第4引数を渡すと、Rails は先に「空っぽの行だけこの値で埋める」UPDATE を流してから
    # NOT NULL を掛ける。既に登録済みのユーザー（開発・本番とも）がいても落ちない。
    # 仮の値は DB に残るので、画面から正しい値に入れ直す
    change_column_null :users, :school_name,        false, "未設定"
    change_column_null :users, :academic_year,      false, "2026"
    change_column_null :users, :current_enrollment, false, 1
  end
end
