import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 },
    maxVisible: { type: Number, default: 3 }
  }

  connect () {
    this.boundHandleError = this.handleError.bind(this)
    window.addEventListener('stream-table-preferences:error', this.boundHandleError)
  }

  disconnect () {
    window.removeEventListener('stream-table-preferences:error', this.boundHandleError)
  }

  handleError (event) {
    const detail = event.detail || {}
    const message = detail.message || 'Something went wrong'
    const errorMessage = detail.error && detail.error.message ? detail.error.message : null

    this.showToast({
      title: 'Update failed',
      message,
      detail: errorMessage
    })
  }

  showToast ({ title, message, detail }) {
    const toast = this.buildToast({ title, message, detail })
    this.element.appendChild(toast)
    this.trimToasts()

    requestAnimationFrame(() => {
      toast.classList.remove('opacity-0', 'translate-y-2')
      toast.classList.add('opacity-100', 'translate-y-0')
    })

    const timeoutId = window.setTimeout(() => this.dismissToast(toast), this.durationValue)
    toast.dataset.timeoutId = String(timeoutId)
  }

  dismissToast (toast) {
    if (!toast || !toast.isConnected) return

    const timeoutId = toast.dataset.timeoutId
    if (timeoutId) {
      window.clearTimeout(Number(timeoutId))
    }

    toast.classList.remove('opacity-100', 'translate-y-0')
    toast.classList.add('opacity-0', 'translate-y-2')

    window.setTimeout(() => {
      toast.remove()
    }, 200)
  }

  trimToasts () {
    const toasts = Array.from(this.element.querySelectorAll('[data-toast]'))
    if (toasts.length <= this.maxVisibleValue) return

    const excess = toasts.length - this.maxVisibleValue
    toasts.slice(0, excess).forEach(toast => this.dismissToast(toast))
  }

  buildToast ({ title, message, detail }) {
    const toast = document.createElement('div')
    toast.dataset.toast = 'true'
    toast.className = [
      'pointer-events-auto',
      'w-80',
      'rounded-lg',
      'border',
      'border-red-200',
      'bg-red-50',
      'shadow-lg',
      'opacity-0',
      'translate-y-2',
      'transition',
      'duration-200',
      'ease-out'
    ].join(' ')

    const body = document.createElement('div')
    body.className = 'flex items-start gap-3 p-3'

    const icon = document.createElement('div')
    icon.className = 'text-red-600'
    icon.innerHTML = '<svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v4a1 1 0 102 0V7zm-1 7a1.25 1.25 0 110-2.5 1.25 1.25 0 010 2.5z" clip-rule="evenodd"></path></svg>'

    const content = document.createElement('div')
    content.className = 'flex-1'

    const titleEl = document.createElement('p')
    titleEl.className = 'text-sm font-semibold text-red-900'
    titleEl.textContent = title

    const messageEl = document.createElement('p')
    messageEl.className = 'text-sm text-red-800'
    messageEl.textContent = message

    content.appendChild(titleEl)
    content.appendChild(messageEl)

    if (detail && detail !== message) {
      const detailEl = document.createElement('p')
      detailEl.className = 'mt-1 text-xs text-red-700'
      detailEl.textContent = detail
      content.appendChild(detailEl)
    }

    const closeButton = document.createElement('button')
    closeButton.type = 'button'
    closeButton.className = 'text-red-500 hover:text-red-700'
    closeButton.setAttribute('aria-label', 'Dismiss notification')
    closeButton.innerHTML = '<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>'
    closeButton.addEventListener('click', () => this.dismissToast(toast))

    body.appendChild(icon)
    body.appendChild(content)
    body.appendChild(closeButton)
    toast.appendChild(body)

    return toast
  }
}
