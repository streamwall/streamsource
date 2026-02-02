import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['textarea', 'counter']

  connect () {
    this.update()
  }

  update () {
    const length = this.textareaTarget.value.length
    const maxLength = this.textareaTarget.getAttribute('maxlength') || 2000

    this.counterTarget.textContent = `${length}/${maxLength}`

    // Change color based on usage
    if (length > maxLength * 0.9) {
      this.counterTarget.classList.remove('text-gray-400', 'text-yellow-500')
      this.counterTarget.classList.add('text-red-500')
    } else if (length > maxLength * 0.75) {
      this.counterTarget.classList.remove('text-gray-400', 'text-red-500')
      this.counterTarget.classList.add('text-yellow-500')
    } else {
      this.counterTarget.classList.remove('text-red-500', 'text-yellow-500')
      this.counterTarget.classList.add('text-gray-400')
    }
  }
}
