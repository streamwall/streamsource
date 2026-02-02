import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ['form']
  static values = { delay: Number }

  connect () {
    this.delayValue = this.delayValue || 300
  }

  submit () {
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, this.delayValue)
  }

  clear () {
    this.formTarget.reset()
    this.formTarget.requestSubmit()
  }
}
