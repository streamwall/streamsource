import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Close modal on ESC key
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Remove the modal frame content
    this.element.innerHTML = ""
  }

  // Close modal when clicking outside
  closeOnClickOutside(event) {
    if (event.target === this.containerTarget) {
      this.close()
    }
  }
}