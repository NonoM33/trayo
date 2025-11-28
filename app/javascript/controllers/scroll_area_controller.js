import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["root", "viewport", "scrollbar", "thumb"]
  static values = {
    hideDelay: { type: Number, default: 600 },
    orientation: { type: String, default: "vertical" }
  }

  connect() {
    this.isHovering = false
    this.isScrolling = false
    this.isDragging = false
    this.hideTimeout = null
    
    this.updateOverflowState()
    this.updateThumbSize()
    
    window.addEventListener("resize", this.handleResize.bind(this))
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize.bind(this))
    if (this.hideTimeout) clearTimeout(this.hideTimeout)
  }

  handleResize() {
    this.updateOverflowState()
    this.updateThumbSize()
  }

  onRootMouseEnter() {
    this.isHovering = true
    this.showScrollbars()
  }

  onRootMouseLeave() {
    this.isHovering = false
    if (!this.isDragging) {
      this.scheduleHide()
    }
  }

  onViewportScroll() {
    this.updateThumbPosition()
    this.updateOverflowState()
    this.showScrollbars()
    this.scheduleHide()
  }

  onScrollbarClick(event) {
    if (event.target === event.currentTarget) {
      const scrollbar = event.currentTarget
      const orientation = scrollbar.dataset.scrollAreaOrientationValue
      const rect = scrollbar.getBoundingClientRect()
      
      if (orientation === "vertical") {
        const clickPosition = (event.clientY - rect.top) / rect.height
        const scrollHeight = this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight
        this.viewportTarget.scrollTop = clickPosition * scrollHeight
      } else {
        const clickPosition = (event.clientX - rect.left) / rect.width
        const scrollWidth = this.viewportTarget.scrollWidth - this.viewportTarget.clientWidth
        this.viewportTarget.scrollLeft = clickPosition * scrollWidth
      }
    }
  }

  onThumbMouseDown(event) {
    event.preventDefault()
    this.isDragging = true
    
    const thumb = event.currentTarget
    const scrollbar = thumb.parentElement
    const orientation = scrollbar.dataset.scrollAreaOrientationValue
    
    const startPos = orientation === "vertical" ? event.clientY : event.clientX
    const startScroll = orientation === "vertical" 
      ? this.viewportTarget.scrollTop 
      : this.viewportTarget.scrollLeft
    
    const onMouseMove = (e) => {
      const currentPos = orientation === "vertical" ? e.clientY : e.clientX
      const delta = currentPos - startPos
      const scrollbarRect = scrollbar.getBoundingClientRect()
      const scrollbarSize = orientation === "vertical" ? scrollbarRect.height : scrollbarRect.width
      const contentSize = orientation === "vertical" 
        ? this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight
        : this.viewportTarget.scrollWidth - this.viewportTarget.clientWidth
      
      const scrollDelta = (delta / scrollbarSize) * contentSize
      
      if (orientation === "vertical") {
        this.viewportTarget.scrollTop = startScroll + scrollDelta
      } else {
        this.viewportTarget.scrollLeft = startScroll + scrollDelta
      }
    }
    
    const onMouseUp = () => {
      this.isDragging = false
      document.removeEventListener("mousemove", onMouseMove)
      document.removeEventListener("mouseup", onMouseUp)
      
      if (!this.isHovering) {
        this.scheduleHide()
      }
    }
    
    document.addEventListener("mousemove", onMouseMove)
    document.addEventListener("mouseup", onMouseUp)
  }

  showScrollbars() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
      this.hideTimeout = null
    }
    
    this.scrollbarTargets.forEach(scrollbar => {
      scrollbar.dataset.scrolling = "true"
    })
  }

  scheduleHide() {
    if (this.hideTimeout) clearTimeout(this.hideTimeout)
    
    this.hideTimeout = setTimeout(() => {
      if (!this.isHovering && !this.isDragging) {
        this.scrollbarTargets.forEach(scrollbar => {
          delete scrollbar.dataset.scrolling
        })
      }
    }, this.hideDelayValue)
  }

  updateOverflowState() {
    const viewport = this.viewportTarget
    const root = this.hasRootTarget ? this.rootTarget : this.element
    
    const hasOverflowX = viewport.scrollWidth > viewport.clientWidth
    const hasOverflowY = viewport.scrollHeight > viewport.clientHeight
    
    root.dataset.hasOverflowX = hasOverflowX
    root.dataset.hasOverflowY = hasOverflowY
    
    if (viewport.scrollLeft > 0) {
      root.dataset.overflowXStart = ""
    } else {
      delete root.dataset.overflowXStart
    }
    
    if (viewport.scrollLeft < viewport.scrollWidth - viewport.clientWidth - 1) {
      root.dataset.overflowXEnd = ""
    } else {
      delete root.dataset.overflowXEnd
    }
    
    if (viewport.scrollTop > 0) {
      root.dataset.overflowYStart = ""
    } else {
      delete root.dataset.overflowYStart
    }
    
    if (viewport.scrollTop < viewport.scrollHeight - viewport.clientHeight - 1) {
      root.dataset.overflowYEnd = ""
    } else {
      delete root.dataset.overflowYEnd
    }
    
    this.scrollbarTargets.forEach(scrollbar => {
      const orientation = scrollbar.dataset.scrollAreaOrientationValue
      const hasOverflow = orientation === "vertical" ? hasOverflowY : hasOverflowX
      scrollbar.dataset.visible = hasOverflow
    })
  }

  updateThumbSize() {
    this.thumbTargets.forEach((thumb, index) => {
      const scrollbar = this.scrollbarTargets[index]
      if (!scrollbar) return
      
      const orientation = scrollbar.dataset.scrollAreaOrientationValue
      const viewport = this.viewportTarget
      
      if (orientation === "vertical") {
        const ratio = viewport.clientHeight / viewport.scrollHeight
        const thumbHeight = Math.max(ratio * 100, 10)
        thumb.style.height = `${thumbHeight}%`
      } else {
        const ratio = viewport.clientWidth / viewport.scrollWidth
        const thumbWidth = Math.max(ratio * 100, 10)
        thumb.style.width = `${thumbWidth}%`
      }
    })
  }

  updateThumbPosition() {
    this.thumbTargets.forEach((thumb, index) => {
      const scrollbar = this.scrollbarTargets[index]
      if (!scrollbar) return
      
      const orientation = scrollbar.dataset.scrollAreaOrientationValue
      const viewport = this.viewportTarget
      
      if (orientation === "vertical") {
        const scrollRatio = viewport.scrollTop / (viewport.scrollHeight - viewport.clientHeight)
        const thumbHeight = thumb.offsetHeight
        const trackHeight = scrollbar.offsetHeight
        const maxOffset = trackHeight - thumbHeight
        thumb.style.top = `${scrollRatio * maxOffset}px`
      } else {
        const scrollRatio = viewport.scrollLeft / (viewport.scrollWidth - viewport.clientWidth)
        const thumbWidth = thumb.offsetWidth
        const trackWidth = scrollbar.offsetWidth
        const maxOffset = trackWidth - thumbWidth
        thumb.style.left = `${scrollRatio * maxOffset}px`
      }
    })
  }
}

