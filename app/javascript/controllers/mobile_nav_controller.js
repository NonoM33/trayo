import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "drawerPanel"]

  openMenu() {
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.remove("hidden")
      document.body.style.overflow = "hidden"
      
      requestAnimationFrame(() => {
        if (this.hasDrawerPanelTarget) {
          this.drawerPanelTarget.style.transform = "translateY(0)"
        }
      })
    }
  }

  closeMenu() {
    if (this.hasDrawerPanelTarget) {
      this.drawerPanelTarget.style.transform = "translateY(100%)"
    }
    
    setTimeout(() => {
      if (this.hasDrawerTarget) {
        this.drawerTarget.classList.add("hidden")
        document.body.style.overflow = ""
      }
    }, 300)
  }

  connect() {
    if (this.hasDrawerPanelTarget) {
      this.drawerPanelTarget.style.transform = "translateY(100%)"
    }
    
    document.addEventListener('keydown', this.handleEscape.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleEscape.bind(this))
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.closeMenu()
    }
  }
}

