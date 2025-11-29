import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  toggle() {
    const input = this.inputTarget
    const icon = this.iconTarget
    
    if (input.type === "password") {
      input.type = "text"
      icon.classList.remove("fa-eye")
      icon.classList.add("fa-eye-slash")
    } else {
      input.type = "password"
      icon.classList.remove("fa-eye-slash")
      icon.classList.add("fa-eye")
    }
  }

  copy() {
    const input = this.inputTarget
    const originalType = input.type
    
    input.type = "text"
    input.select()
    input.setSelectionRange(0, 99999)
    
    navigator.clipboard.writeText(input.value).then(() => {
      this.showCopyFeedback()
    }).catch(() => {
      document.execCommand("copy")
      this.showCopyFeedback()
    })
    
    input.type = originalType
    input.setSelectionRange(0, 0)
  }

  showCopyFeedback() {
    const btn = this.element.querySelector('[data-action*="copy"]')
    if (btn) {
      const icon = btn.querySelector('i')
      const originalClass = icon.className
      icon.className = "fa-solid fa-check text-xs"
      btn.classList.add("text-emerald-400")
      
      setTimeout(() => {
        icon.className = originalClass
        btn.classList.remove("text-emerald-400")
      }, 1500)
    }
  }
}

