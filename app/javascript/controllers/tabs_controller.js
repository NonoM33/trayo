import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { default: String }

  connect() {
    const defaultTab = this.defaultValue || this.tabTargets[0]?.dataset.tab
    if (defaultTab) {
      this.showTab(defaultTab)
    }
  }

  select(event) {
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
  }

  showTab(tabName) {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      if (isActive) {
        tab.classList.add("bg-neutral-800", "text-white", "border", "border-neutral-700")
        tab.classList.remove("text-neutral-400", "hover:text-white", "hover:bg-neutral-800/50")
      } else {
        tab.classList.remove("bg-neutral-800", "text-white", "border", "border-neutral-700")
        tab.classList.add("text-neutral-400", "hover:text-white", "hover:bg-neutral-800/50")
      }
    })

    this.panelTargets.forEach(panel => {
      if (panel.dataset.tab === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}

