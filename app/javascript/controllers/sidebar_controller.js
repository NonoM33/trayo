import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["desktopSidebar", "mobileSidebar", "mobileBackdrop", "mobilePanel", "desktopContent", "sharedContent"]
  static values = { storageKey: String }


  initDesktopSidebar() {
    if (!this.hasDesktopSidebarTarget) return
    
    const details = this.desktopSidebarTarget
    const isOpen = localStorage.getItem(this.storageKey) !== "closed"
    
    if (isOpen) {
      details.setAttribute("open", "")
    } else {
      details.removeAttribute("open")
    }
  }

  initMobileSidebar() {
    if (!this.hasMobileSidebarTarget) return
    
    const mobileSidebar = this.mobileSidebarTarget
    mobileSidebar.classList.add("hidden")
  }

  open() {
    if (this.hasDesktopSidebarTarget) {
      this.desktopSidebarTarget.setAttribute("open", "")
      localStorage.setItem(this.storageKey, "open")
    }
    this.updateMainContent()
  }

  close() {
    if (this.hasDesktopSidebarTarget) {
      this.desktopSidebarTarget.removeAttribute("open")
      localStorage.setItem(this.storageKey, "closed")
    }
    this.updateMainContent()
  }

  openMobile() {
    if (this.hasMobileSidebarTarget) {
      this.mobileSidebarTarget.classList.remove("hidden")
      document.body.style.overflow = "hidden"
    }
  }

  closeMobile() {
    if (this.hasMobileSidebarTarget) {
      this.mobileSidebarTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }
  }

  updateMainContent() {
    const mainContainer = document.getElementById('mainContainer')
    
    if (mainContainer) {
      const isOpen = this.hasDesktopSidebarTarget && this.desktopSidebarTarget.hasAttribute("open")
      if (window.innerWidth >= 768) {
        mainContainer.style.marginLeft = isOpen ? "256px" : "52px"
        mainContainer.style.transition = "margin-left 0.3s"
      } else {
        mainContainer.style.marginLeft = "0"
      }
    }
  }
  
  connect() {
    this.storageKey = this.storageKeyValue || "trayoSidebar"
    this.initDesktopSidebar()
    this.initMobileSidebar()
    this.updateMainContent()
    
    const details = this.desktopSidebarTarget
    if (details) {
      details.addEventListener('toggle', () => {
        setTimeout(() => this.updateMainContent(), 10)
      })
    }
    
    window.addEventListener('resize', () => {
      this.updateMainContent()
    })
  }
}
