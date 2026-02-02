import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu', 'overlay']

  connect () {
    this.menuElement = document.getElementById('mobile-menu')
    this.overlayElement = document.getElementById('mobile-menu-overlay')
  }

  toggle () {
    if (this.menuElement.classList.contains('-translate-x-full')) {
      this.open()
    } else {
      this.close()
    }
  }

  open () {
    this.menuElement.classList.remove('-translate-x-full')
    this.overlayElement.classList.remove('hidden')
    document.body.classList.add('overflow-hidden')
  }

  close () {
    this.menuElement.classList.add('-translate-x-full')
    this.overlayElement.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }
}
