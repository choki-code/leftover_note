module ApplicationHelper
  # 保存に失敗したときのエラーを、フォームの上にまとめて出す（6-C）。
  # どのフォームでも同じ見た目・同じ文言にするためにヘルパーへ寄せている。
  # エラーが無いときは nil を返すので、呼び出し側で if を書かなくてよい。
  def error_summary(record)
    return if record.blank? || record.errors.empty?

    tag.div class: "error-summary", role: "alert" do
      concat tag.p(t("errors.summary", count: record.errors.count))
      concat tag.ul(safe_join(record.errors.full_messages.map { |message| tag.li(message) }))
    end
  end
end
