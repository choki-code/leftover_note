import { Controller } from "@hotwired/stimulus"

// #22 献立フォームで料理を選ぶと、その料理の履歴（#21）へのリンクを出す
export default class extends Controller {
  static targets = ["select", "link"]
  static values = { url: String }

  connect() {
    this.update()
  }

  update() {
    const dishId = this.selectTarget.value
    if (dishId) {
      this.linkTarget.href = `${this.urlValue}/${dishId}`
      this.linkTarget.hidden = false
    } else {
      this.linkTarget.hidden = true
    }
  }
}
