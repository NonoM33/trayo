import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    position: { type: String, default: "top-center" },
    duration: { type: Number, default: 4000 }
  }

  connect() {
    window.toast = this.showToast.bind(this)
    window.addEventListener("toast-show", this.handleToastShow.bind(this))
  }

  showToast(message, options = {}) {
    const detail = {
      type: options.type || "default",
      message: message,
      description: options.description || ""
    }
    window.dispatchEvent(new CustomEvent("toast-show", { detail }))
  }

  handleToastShow(event) {
    const { type, message, description } = event.detail
    this.createToast(type, message, description)
  }

  createToast(type, message, description) {
    const toast = document.createElement("div")
    toast.className = "toast-notification transform translate-y-[-100%] opacity-0 transition-all duration-300 ease-out"
    
    const colors = {
      success: { bg: "from-emerald-500/20 to-emerald-600/10", border: "border-emerald-500/40", icon: "fa-check-circle", iconColor: "text-emerald-400" },
      error: { bg: "from-red-500/20 to-red-600/10", border: "border-red-500/40", icon: "fa-exclamation-circle", iconColor: "text-red-400" },
      warning: { bg: "from-amber-500/20 to-amber-600/10", border: "border-amber-500/40", icon: "fa-exclamation-triangle", iconColor: "text-amber-400" },
      info: { bg: "from-blue-500/20 to-blue-600/10", border: "border-blue-500/40", icon: "fa-info-circle", iconColor: "text-blue-400" },
      default: { bg: "from-neutral-500/20 to-neutral-600/10", border: "border-neutral-500/40", icon: "fa-bell", iconColor: "text-neutral-400" }
    }

    const style = colors[type] || colors.default

    toast.innerHTML = `
      <div class="flex items-start gap-3 px-4 py-3.5 rounded-xl bg-gradient-to-r ${style.bg} border ${style.border} backdrop-blur-xl shadow-2xl shadow-black/20 min-w-[300px] max-w-[400px]">
        <div class="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0">
          <i class="fa-solid ${style.icon} ${style.iconColor}"></i>
        </div>
        <div class="flex-1 min-w-0 pt-0.5">
          <p class="text-sm font-semibold text-white">${message}</p>
          ${description ? `<p class="text-xs text-neutral-400 mt-0.5">${description}</p>` : ''}
        </div>
        <button type="button" class="toast-close p-1 rounded-lg text-neutral-400 hover:text-white hover:bg-white/10 transition-colors">
          <i class="fa-solid fa-xmark text-sm"></i>
        </button>
      </div>
    `

    this.containerTarget.appendChild(toast)

    toast.querySelector('.toast-close').addEventListener('click', () => this.removeToast(toast))

    requestAnimationFrame(() => {
      toast.classList.remove("translate-y-[-100%]", "opacity-0")
      toast.classList.add("translate-y-0", "opacity-100")
    })

    setTimeout(() => this.removeToast(toast), this.durationValue)
  }

  removeToast(toast) {
    if (!toast || toast.dataset.removing) return
    toast.dataset.removing = "true"
    
    toast.classList.add("translate-y-[-100%]", "opacity-0")
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 300)
  }
}

