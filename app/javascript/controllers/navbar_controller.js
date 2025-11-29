import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updatePosition()
    
    const sidebar = document.querySelector('[data-controller="sidebar"]')
    if (sidebar) {
      const desktopSidebar = sidebar.querySelector('[data-sidebar-target="desktopSidebar"]')
      if (desktopSidebar) {
        const observer = new MutationObserver(() => {
          setTimeout(() => this.updatePosition(), 10)
        })
        observer.observe(desktopSidebar, { attributes: true, attributeFilter: ['open'] })
      }
    }
    
    window.addEventListener('resize', this.updatePosition.bind(this))
  }

  updatePosition() {
    const sidebar = document.querySelector('[data-sidebar-target="desktopSidebar"]')
    
    if (window.innerWidth >= 768 && sidebar) {
      const isOpen = sidebar.hasAttribute('open')
      this.element.style.left = isOpen ? '256px' : '52px'
    } else {
      this.element.style.left = '0'
    }
  }
}

