import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['panel', 'trigger']

  connect () {
    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleDocumentKeydown = this.handleDocumentKeydown.bind(this)
  }

  disconnect () {
    this.removeDocumentListeners()
  }

  toggle (event) {
    if (event) event.preventDefault()
    if (event) event.stopPropagation()

    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open () {
    if (this.isOpen()) return

    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    document.addEventListener('pointerdown', this.handleDocumentClick)
    document.addEventListener('keydown', this.handleDocumentKeydown)
    this.focusFirstInput()
  }

  close () {
    if (!this.isOpen()) return

    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute('aria-expanded', 'false')
    this.removeDocumentListeners()
  }

  handleDocumentClick (event) {
    const path = event.composedPath ? event.composedPath() : []
    if (path.includes(this.element) || this.element.contains(event.target)) return

    this.close()
  }

  handleDocumentKeydown (event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  removeDocumentListeners () {
    document.removeEventListener('pointerdown', this.handleDocumentClick)
    document.removeEventListener('keydown', this.handleDocumentKeydown)
  }

  keepOpen (event) {
    if (event) event.stopPropagation()
  }

  focusFirstInput () {
    const input = this.findFocusableInput()
    if (input) {
      requestAnimationFrame(() => {
        input.focus({ preventScroll: true })
        if (input.select) input.select()
      })
      setTimeout(() => {
        input.focus({ preventScroll: true })
      }, 0)
    }
  }

  findFocusableInput () {
    const candidates = Array.from(
      this.panelTarget.querySelectorAll('input, select, textarea, button')
    )

    return candidates.find((element) => {
      if (element.disabled) return false
      if (element.tagName.toLowerCase() === 'input') {
        return element.type !== 'hidden'
      }
      return true
    })
  }

  isOpen () {
    return !this.panelTarget.hidden
  }
}
