import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panel", "backdrop"]
  static values = { id: String }

  connect() {
    document.addEventListener("slide-panel:open", this.handleGlobalOpen.bind(this))
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("slide-panel:open", this.handleGlobalOpen.bind(this))
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleGlobalOpen(event) {
    if (event.detail.id === this.idValue) {
      this.openPanel()
    }
  }

  open(event) {
    const panelId = event.params?.id
    if (panelId) {
      document.dispatchEvent(new CustomEvent("slide-panel:open", { detail: { id: panelId } }))
    } else {
      this.openPanel()
    }
  }

  openPanel() {
    this.containerTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
      this.backdropTarget.classList.add("opacity-100")
    })
  }

  close() {
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.remove("opacity-100")
    
    setTimeout(() => {
      this.containerTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }, 300)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.containerTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  submitForm(event) {
    // Let the form submit normally, the page will reload
  }
}

