import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['toggle']
  static values = {
    storageKey: { type: String, default: 'streamsViewMode' }
  }

  connect () {
    this.boundHandleMediaChange = this.handleMediaChange.bind(this)
    this.mediaQuery = window.matchMedia('(min-width: 768px)')

    this.applySavedOrDefault()
    this.addMediaListener()
  }

  disconnect () {
    this.removeMediaListener()
  }

  select (event) {
    const mode = event.currentTarget.dataset.mode
    if (!this.isValidMode(mode)) return

    this.storeMode(mode)
    this.applyMode(mode)
  }

  handleMediaChange () {
    this.applySavedOrDefault()
  }

  defaultMode () {
    return this.mediaQuery.matches ? 'table' : 'card'
  }

  applySavedOrDefault () {
    const savedMode = this.loadSavedMode()
    if (savedMode) {
      this.applyMode(savedMode)
      return
    }

    this.applyMode(this.defaultMode())
  }

  applyMode (mode) {
    if (!this.isValidMode(mode)) return

    this.element.dataset.streamViewMode = mode
    this.updateToggleStyles(mode)
  }

  updateToggleStyles (mode) {
    if (!this.hasToggleTarget) return

    this.toggleTargets.forEach(toggle => {
      const active = toggle.dataset.mode === mode
      toggle.setAttribute('aria-pressed', active ? 'true' : 'false')
      toggle.classList.toggle('bg-indigo-600', active)
      toggle.classList.toggle('text-white', active)
      toggle.classList.toggle('hover:bg-indigo-700', active)
      toggle.classList.toggle('bg-white', !active)
      toggle.classList.toggle('text-gray-600', !active)
      toggle.classList.toggle('hover:text-gray-900', !active)
      toggle.classList.toggle('hover:bg-gray-50', !active)
    })
  }

  isValidMode (mode) {
    return mode === 'table' || mode === 'card'
  }

  loadSavedMode () {
    try {
      const mode = window.localStorage.getItem(this.storageKey())
      return this.isValidMode(mode) ? mode : null
    } catch {
      return null
    }
  }

  storeMode (mode) {
    try {
      window.localStorage.setItem(this.storageKey(), mode)
    } catch {
      // Ignore storage errors (private mode, disabled storage, etc.)
    }
  }

  storageKey () {
    const suffix = this.mediaQuery && this.mediaQuery.matches ? 'desktop' : 'mobile'
    return `${this.storageKeyValue}-${suffix}`
  }

  addMediaListener () {
    if (!this.mediaQuery) return

    if (this.mediaQuery.addEventListener) {
      this.mediaQuery.addEventListener('change', this.boundHandleMediaChange)
    } else if (this.mediaQuery.addListener) {
      this.mediaQuery.addListener(this.boundHandleMediaChange)
    }
  }

  removeMediaListener () {
    if (!this.mediaQuery) return

    if (this.mediaQuery.removeEventListener) {
      this.mediaQuery.removeEventListener('change', this.boundHandleMediaChange)
    } else if (this.mediaQuery.removeListener) {
      this.mediaQuery.removeListener(this.boundHandleMediaChange)
    }
  }
}
