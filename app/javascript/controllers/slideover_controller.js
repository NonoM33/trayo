import { Controller } from "@hotwired/stimulus";

if (!window.__openDialogCount) {
  window.__openDialogCount = 0;
}

if (!window.__dialogCountResetBound) {
  window.__dialogCountResetBound = true;

  const resetDialogCount = () => {
    const openDialogs = document.querySelectorAll("dialog[open]");
    if (openDialogs.length === 0) {
      window.__openDialogCount = 0;
      document.documentElement.style.removeProperty("--scrollbar-compensation");
      document.body.classList.remove("modal-open", "slideover-open");
    } else {
      window.__openDialogCount = openDialogs.length;
    }
  };

  document.addEventListener("turbo:before-cache", resetDialogCount);
  document.addEventListener("turbo:load", resetDialogCount);
}

export default class extends Controller {
  static targets = ["dialog", "template"];
  static values = {
    open: { type: Boolean, default: false },
    lazyLoad: { type: Boolean, default: false },
    turboFrameSrc: { type: String, default: "" },
    autoFocus: { type: Boolean, default: false },
  };

  connect() {
    this.contentLoaded = false;
    this.isOpen = false;
    this.focusableElements = [];
    this.firstFocusableElement = null;
    this.lastFocusableElement = null;

    if (this.dialogTarget.open) {
      this.isOpen = true;
      this.dialogTarget.close();
      this.cleanupScrollbarCompensation();
    }

    if (this.openValue) this.open();

    this.boundBeforeCache = this.beforeCache.bind(this);
    this.boundBeforeVisit = this.beforeVisit.bind(this);
    document.addEventListener("turbo:before-cache", this.boundBeforeCache);
    document.addEventListener("turbo:before-visit", this.boundBeforeVisit);

    this.dialogTarget.addEventListener("close", this.handleDialogClose.bind(this));
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.dialogTarget.addEventListener("keydown", this.boundHandleKeydown);
  }

  disconnect() {
    if (this.isOpen) {
      this.cleanupScrollbarCompensation();
    }

    document.removeEventListener("turbo:before-cache", this.boundBeforeCache);
    document.removeEventListener("turbo:before-visit", this.boundBeforeVisit);
    this.dialogTarget.removeEventListener("close", this.handleDialogClose.bind(this));
    this.dialogTarget.removeEventListener("keydown", this.boundHandleKeydown);
  }

  async open() {
    if (this.isOpen) return;

    if (this.lazyLoadValue && !this.contentLoaded) {
      await this.#loadTemplateContent();
      this.contentLoaded = true;
    }

    window.__openDialogCount++;
    this.isOpen = true;

    if (window.__openDialogCount === 1) {
      const scrollbarWidth = this.getScrollbarWidth();
      if (scrollbarWidth > 0) {
        document.documentElement.style.setProperty("--scrollbar-compensation", `${scrollbarWidth}px`);
        document.body.classList.add("slideover-open");
      }
    }

    this.dialogTarget.showModal();
    this.setupFocusTrapping();
  }

  close() {
    if (!this.isOpen) return;

    this.dialogTarget.setAttribute("closing", "");

    Promise.all(this.dialogTarget.getAnimations().map((animation) => animation.finished)).then(() => {
      this.dialogTarget.removeAttribute("closing");
      this.dialogTarget.close();
    });
  }

  backdropClose(event) {
    if (event.target.nodeName === "DIALOG") {
      event.stopPropagation();
      this.close();
    }
  }

  show() {
    this.open();
  }

  hide(event) {
    if (event) event.preventDefault();
    this.close();
  }

  beforeCache() {
    if (this.isOpen) {
      this.dialogTarget.removeAttribute("closing");
      this.dialogTarget.close();
      this.cleanupScrollbarCompensation();
    }
  }

  beforeVisit() {
    if (this.isOpen) {
      this.dialogTarget.removeAttribute("closing");
      this.dialogTarget.close();
      this.cleanupScrollbarCompensation();
    }
  }

  getScrollbarWidth() {
    const outer = document.createElement("div");
    outer.style.visibility = "hidden";
    outer.style.overflow = "scroll";
    outer.style.msOverflowStyle = "scrollbar";
    document.body.appendChild(outer);

    const inner = document.createElement("div");
    outer.appendChild(inner);

    const scrollbarWidth = outer.offsetWidth - inner.offsetWidth;
    outer.parentNode.removeChild(outer);

    return scrollbarWidth;
  }

  async #loadTemplateContent() {
    const container = this.dialogTarget.querySelector("[data-slideover-content]") || this.dialogTarget;

    if (this.turboFrameSrcValue) {
      let turboFrame = container.querySelector("turbo-frame");

      if (!turboFrame) {
        turboFrame = document.createElement("turbo-frame");
        turboFrame.id = "slideover-lazy-content";
        container.innerHTML = "";
        container.appendChild(turboFrame);
      }

      turboFrame.src = this.turboFrameSrcValue;

      return new Promise((resolve) => {
        const handleLoad = () => {
          turboFrame.removeEventListener("turbo:frame-load", handleLoad);
          resolve();
        };

        turboFrame.addEventListener("turbo:frame-load", handleLoad);

        setTimeout(() => {
          turboFrame.removeEventListener("turbo:frame-load", handleLoad);
          resolve();
        }, 5000);
      });
    } else if (this.hasTemplateTarget) {
      const templateContent = this.templateTarget.content.cloneNode(true);
      container.innerHTML = "";
      container.appendChild(templateContent);
    }
  }

  handleDialogClose() {
    if (this.isOpen) {
      this.cleanupScrollbarCompensation();
    }
    this.dialogTarget.removeAttribute("closing");
  }

  cleanupScrollbarCompensation() {
    if (!this.isOpen) return;

    window.__openDialogCount = Math.max(0, window.__openDialogCount - 1);
    this.isOpen = false;

    if (window.__openDialogCount === 0) {
      document.documentElement.style.removeProperty("--scrollbar-compensation");
      document.body.classList.remove("modal-open", "slideover-open");
    }
  }

  handleKeydown(event) {
    if (event.key === "Tab") {
      this.handleTabKey(event);
    }
  }

  setupFocusTrapping() {
    this.updateFocusableElements();

    const autofocusElement = this.dialogTarget.querySelector("[autofocus]");
    if (autofocusElement) {
      autofocusElement.focus();
    } else if (this.autoFocusValue && this.firstFocusableElement) {
      this.firstFocusableElement.focus();
    }
  }

  updateFocusableElements() {
    const focusableSelector = [
      "a[href]",
      "area[href]",
      'input:not([disabled]):not([tabindex="-1"])',
      'button:not([disabled]):not([tabindex="-1"])',
      'textarea:not([disabled]):not([tabindex="-1"])',
      'select:not([disabled]):not([tabindex="-1"])',
      "details",
      '[tabindex]:not([tabindex="-1"])',
      '[contenteditable]:not([contenteditable="false"])',
    ].join(",");

    this.focusableElements = Array.from(this.dialogTarget.querySelectorAll(focusableSelector)).filter((element) => {
      return (
        element.offsetWidth > 0 &&
        element.offsetHeight > 0 &&
        getComputedStyle(element).display !== "none" &&
        getComputedStyle(element).visibility !== "hidden"
      );
    });

    this.firstFocusableElement = this.focusableElements[0] || null;
    this.lastFocusableElement = this.focusableElements[this.focusableElements.length - 1] || null;
  }

  handleTabKey(event) {
    this.updateFocusableElements();

    if (this.focusableElements.length === 0) {
      event.preventDefault();
      return;
    }

    if (this.focusableElements.length === 1) {
      event.preventDefault();
      this.firstFocusableElement.focus();
      return;
    }

    if (event.shiftKey) {
      if (document.activeElement === this.firstFocusableElement) {
        event.preventDefault();
        this.lastFocusableElement.focus();
      }
    } else {
      if (document.activeElement === this.lastFocusableElement) {
        event.preventDefault();
        this.firstFocusableElement.focus();
      }
    }
  }
}

