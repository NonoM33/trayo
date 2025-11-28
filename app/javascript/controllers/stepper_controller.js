import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["step", "indicator", "line", "prevButton", "nextButton", "submitButton"];

  static values = {
    currentStep: { type: Number, default: 0 },
    validateOnNext: { type: Boolean, default: true },
    allowSkip: { type: Boolean, default: false },
    scrollOnChange: { type: Boolean, default: false },
    saveProgress: { type: Boolean, default: true },
    storageKey: { type: String, default: "stepper-progress" },
    indicatorBaseClass: { type: String, default: "" },
    indicatorCompleteClass: {
      type: String,
      default: "bg-white text-neutral-900 cursor-pointer hover:ring-2 hover:ring-white/20"
    },
    indicatorCurrentClass: {
      type: String,
      default: "bg-white text-neutral-900 ring-2 ring-white/20 cursor-pointer"
    },
    indicatorVisitedClass: {
      type: String,
      default: "bg-neutral-700 text-neutral-300 border border-neutral-600 cursor-pointer hover:bg-neutral-600"
    },
    indicatorUpcomingClass: {
      type: String,
      default: "bg-neutral-800 text-neutral-500 border border-neutral-700 cursor-not-allowed opacity-75"
    },
    lineBaseClass: { type: String, default: "" },
    lineCompleteClass: { type: String, default: "bg-white" },
    lineIncompleteClass: { type: String, default: "bg-neutral-700" },
  };

  connect() {
    this.formData = this.loadProgress() || {};
    this.visitedSteps = new Set([0]);
    this.updateView();
    this.setupKeyboardNavigation();
  }

  setupKeyboardNavigation() {
    this.element.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        const target = event.target;
        if (target.tagName === 'TEXTAREA') return;
        if (target.tagName === 'BUTTON') return;
        if (target.matches('input, select')) {
          event.preventDefault();
          if (this.currentStepValue === this.stepTargets.length - 1) {
            this.submit(event);
          } else {
            this.next(event);
          }
        }
      }
    });
  }

  next(event) {
    event?.preventDefault();
    if (this.validateOnNextValue && !this.validateCurrentStep()) return;
    if (this.saveProgressValue) this.saveCurrentStepData();
    if (this.currentStepValue < this.stepTargets.length - 1) {
      this.currentStepValue++;
      this.visitedSteps.add(this.currentStepValue);
      this.updateView();
      if (this.scrollOnChangeValue) this.scrollToTop();
    }
  }

  previous(event) {
    event?.preventDefault();
    if (this.saveProgressValue) this.saveCurrentStepData();
    if (this.currentStepValue > 0) {
      this.currentStepValue--;
      this.updateView();
      if (this.scrollOnChangeValue) this.scrollToTop();
    }
  }

  goToStep(event) {
    event?.preventDefault();
    const targetStep = parseInt(event.currentTarget.dataset.step);
    if (this.allowSkipValue || this.visitedSteps.has(targetStep)) {
      if (this.saveProgressValue) this.saveCurrentStepData();
      this.currentStepValue = targetStep;
      this.updateView();
      if (this.scrollOnChangeValue) this.scrollToTop();
    }
  }

  validateCurrentStep() {
    const currentStep = this.stepTargets[this.currentStepValue];
    if (!currentStep) return true;
    const requiredInputs = currentStep.querySelectorAll("input[required], select[required], textarea[required]");
    let isValid = true;
    requiredInputs.forEach((input) => {
      if (!input.checkValidity()) {
        isValid = false;
        input.reportValidity();
      }
    });
    const validateEvent = new CustomEvent("stepper:validate", {
      detail: { step: this.currentStepValue, isValid },
      bubbles: true,
      cancelable: true,
    });
    this.element.dispatchEvent(validateEvent);
    if (validateEvent.defaultPrevented) isValid = false;
    return isValid;
  }

  saveCurrentStepData() {
    const currentStep = this.stepTargets[this.currentStepValue];
    if (!currentStep) return;
    const inputs = currentStep.querySelectorAll("input, select, textarea");
    inputs.forEach((input) => {
      if (input.name) {
        if (input.type === "checkbox") {
          if (input.name.includes('[]')) {
            const baseName = input.name.replace('[]', '');
            if (!this.formData[baseName]) this.formData[baseName] = [];
            if (input.checked && !this.formData[baseName].includes(input.value)) {
              this.formData[baseName].push(input.value);
            } else if (!input.checked) {
              this.formData[baseName] = this.formData[baseName].filter(v => v !== input.value);
            }
          } else {
            this.formData[input.name] = input.checked;
          }
        } else if (input.type === "radio") {
          if (input.checked) this.formData[input.name] = input.value;
        } else {
          this.formData[input.name] = input.value;
        }
      }
    });
    if (typeof sessionStorage !== "undefined") {
      sessionStorage.setItem(this.storageKeyValue, JSON.stringify(this.formData));
    }
    this.element.dispatchEvent(
      new CustomEvent("stepper:save", {
        detail: { step: this.currentStepValue, data: this.formData },
        bubbles: true,
      })
    );
  }

  loadProgress() {
    if (typeof sessionStorage !== "undefined") {
      const saved = sessionStorage.getItem(this.storageKeyValue);
      if (saved) {
        try { return JSON.parse(saved); } catch (e) { return {}; }
      }
    }
    return {};
  }

  clearProgress() {
    this.formData = {};
    if (typeof sessionStorage !== "undefined") {
      sessionStorage.removeItem(this.storageKeyValue);
    }
  }

  updateView() {
    this.stepTargets.forEach((step, index) => {
      if (index === this.currentStepValue) {
        step.classList.remove("hidden");
        step.classList.add("block");
        this.restoreStepData(step);
      } else {
        step.classList.add("hidden");
        step.classList.remove("block");
      }
    });
    this.updateIndicators();
    this.updateButtons();
    this.updateReviewSections();
    this.element.dispatchEvent(
      new CustomEvent("stepper:change", {
        detail: {
          step: this.currentStepValue,
          totalSteps: this.stepTargets.length,
          isFirst: this.currentStepValue === 0,
          isLast: this.currentStepValue === this.stepTargets.length - 1,
        },
        bubbles: true,
      })
    );
  }

  restoreStepData(step) {
    const inputs = step.querySelectorAll("input, select, textarea");
    inputs.forEach((input) => {
      if (input.name && this.formData[input.name] !== undefined) {
        if (input.type === "checkbox") {
          if (input.name.includes('[]')) {
            const baseName = input.name.replace('[]', '');
            input.checked = this.formData[baseName]?.includes(input.value);
          } else {
            input.checked = this.formData[input.name];
          }
        } else if (input.type === "radio") {
          input.checked = input.value === this.formData[input.name];
        } else {
          input.value = this.formData[input.name];
        }
      }
    });
  }

  updateIndicators() {
    this.indicatorTargets.forEach((indicator, index) => {
      const state = this.getIndicatorState(index);
      this.applyIndicatorState(indicator, state);
      indicator.setAttribute("aria-current", state === 'current' ? "step" : "false");
    });
    if (this.hasLineTarget) {
      this.lineTargets.forEach((line, index) => {
        this.applyLineState(line, index < this.currentStepValue);
      });
    }
  }

  getIndicatorState(index) {
    if (index < this.currentStepValue) return 'complete';
    if (index === this.currentStepValue) return 'current';
    if (this.visitedSteps.has(index)) return 'visited';
    return 'upcoming';
  }

  applyIndicatorState(indicator, state) {
    const numberSpan = indicator.querySelector('.step-number');
    const checkIcon = indicator.querySelector('.step-check');
    if (state === 'complete') {
      numberSpan?.classList.add('hidden');
      checkIcon?.classList.remove('hidden');
    } else {
      numberSpan?.classList.remove('hidden');
      checkIcon?.classList.add('hidden');
    }
    const allStateClasses = [
      this.indicatorCompleteClassValue,
      this.indicatorCurrentClassValue,
      this.indicatorVisitedClassValue,
      this.indicatorUpcomingClassValue
    ].join(' ').split(' ').filter(cls => cls);
    allStateClasses.forEach(cls => indicator.classList.remove(cls));
    if (this.indicatorBaseClassValue) {
      this.indicatorBaseClassValue.split(' ').forEach(cls => {
        if (cls) indicator.classList.add(cls);
      });
    }
    const stateClassMap = {
      complete: this.indicatorCompleteClassValue,
      current: this.indicatorCurrentClassValue,
      visited: this.indicatorVisitedClassValue,
      upcoming: this.indicatorUpcomingClassValue
    };
    const stateClasses = stateClassMap[state];
    if (stateClasses) {
      stateClasses.split(' ').forEach(cls => {
        if (cls) indicator.classList.add(cls);
      });
    }
  }

  applyLineState(line, isComplete) {
    const allStateClasses = [
      this.lineCompleteClassValue,
      this.lineIncompleteClassValue
    ].join(' ').split(' ').filter(cls => cls);
    allStateClasses.forEach(cls => line.classList.remove(cls));
    if (this.lineBaseClassValue) {
      this.lineBaseClassValue.split(' ').forEach(cls => {
        if (cls) line.classList.add(cls);
      });
    }
    const stateClass = isComplete ? this.lineCompleteClassValue : this.lineIncompleteClassValue;
    if (stateClass) {
      stateClass.split(' ').forEach(cls => {
        if (cls) line.classList.add(cls);
      });
    }
  }

  updateButtons() {
    const isFirstStep = this.currentStepValue === 0;
    const isLastStep = this.currentStepValue === this.stepTargets.length - 1;
    if (this.hasPrevButtonTarget) {
      this.prevButtonTargets.forEach((btn) => {
        btn.classList.toggle("hidden", isFirstStep);
        btn.disabled = isFirstStep;
      });
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTargets.forEach((btn) => btn.classList.toggle("hidden", isLastStep));
    }
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTargets.forEach((btn) => btn.classList.toggle("hidden", !isLastStep));
    }
  }

  scrollToTop() {
    this.element.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  updateReviewSections() {
    this.element.querySelectorAll('[data-review-field]').forEach((field) => {
      const fieldName = field.dataset.reviewField;
      if (fieldName === 'full_name' && this.formData.first_name && this.formData.last_name) {
        field.textContent = `${this.formData.first_name} ${this.formData.last_name}`;
        return;
      }
      const value = this.formData[fieldName];
      field.textContent = (value !== undefined && value !== null && value !== '') ? value : '—';
    });
    this.updateProgressBar();
  }

  updateProgressBar() {
    const progressBar = this.element.querySelector('[data-stepper-progress-bar]');
    if (progressBar) {
      const percentage = ((this.currentStepValue + 1) / this.stepTargets.length) * 100;
      progressBar.style.width = `${percentage}%`;
    }
  }

  reset() {
    this.currentStepValue = 0;
    this.clearProgress();
    this.updateView();
  }

  submit(event) {
    event?.preventDefault();
    if (this.validateOnNextValue && !this.validateCurrentStep()) return;
    if (this.saveProgressValue) this.saveCurrentStepData();
    const form = this.element.closest('form') || this.element.querySelector('form');
    if (form) {
      Object.keys(this.formData).forEach(key => {
        let input = form.querySelector(`[name="${key}"]`);
        if (!input) {
          input = document.createElement('input');
          input.type = 'hidden';
          input.name = key;
          form.appendChild(input);
        }
        if (Array.isArray(this.formData[key])) {
          input.value = JSON.stringify(this.formData[key]);
        } else {
          input.value = this.formData[key];
        }
      });
      form.requestSubmit();
    }
  }

  selectBot(event) {
    const card = event.currentTarget;
    const checkbox = card.querySelector('input[type="checkbox"]');
    if (checkbox && event.target !== checkbox) {
      checkbox.checked = !checkbox.checked;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));
    }
    this.updateBotSelection();
  }

  updateBotSelection() {
    const checkboxes = this.element.querySelectorAll('input[name="selected_bots[]"]');
    let total = 0;
    checkboxes.forEach(cb => {
      const card = cb.closest('[data-action*="selectBot"]');
      if (cb.checked) {
        card?.classList.add('ring-2', 'ring-blue-500', 'bg-blue-500/10');
        card?.classList.remove('bg-neutral-800/50');
        total += parseFloat(cb.dataset.price || 0);
      } else {
        card?.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-500/10');
        card?.classList.add('bg-neutral-800/50');
      }
    });
    const totalEl = this.element.querySelector('[data-bots-total]');
    if (totalEl) totalEl.textContent = total.toFixed(2) + ' €';
  }

  selectBroker(event) {
    const card = event.currentTarget;
    const radio = card.querySelector('input[type="radio"]');
    if (radio) {
      radio.checked = true;
      radio.dispatchEvent(new Event('change', { bubbles: true }));
    }
    this.element.querySelectorAll('[data-action*="selectBroker"]').forEach(c => {
      c.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-500/10');
      c.classList.add('bg-neutral-800/50');
    });
    card.classList.add('ring-2', 'ring-blue-500', 'bg-blue-500/10');
    card.classList.remove('bg-neutral-800/50');
  }

  selectQuizAnswer(event) {
    const card = event.currentTarget;
    const questionGroup = card.closest('[data-quiz-question]');
    const radio = card.querySelector('input[type="radio"]');
    if (radio) {
      radio.checked = true;
      radio.dispatchEvent(new Event('change', { bubbles: true }));
    }
    questionGroup.querySelectorAll('[data-action*="selectQuizAnswer"]').forEach(c => {
      c.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-500/10');
      c.classList.add('bg-neutral-800/50', 'hover:bg-neutral-700/50');
    });
    card.classList.add('ring-2', 'ring-blue-500', 'bg-blue-500/10');
    card.classList.remove('bg-neutral-800/50', 'hover:bg-neutral-700/50');
  }
}

