import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'list', 'hidden']
  static values = {
    options: Array,
    maxResults: { type: Number, default: 30 }
  }

  connect () {
    this.allOptions = this.normalizeOptions(this.optionsValue || [])
    this.closeList()
  }

  show () {
    this.filter()
  }

  filter () {
    const query = this.inputTarget.value.trim().toLowerCase()
    const matches = query.length === 0
      ? this.allOptions
      : this.allOptions.filter(option => option.label.toLowerCase().includes(query))

    this.renderList(matches.slice(0, this.maxResultsValue))
    this.openList()
  }

  scheduleClose () {
    clearTimeout(this.closeTimeout)
    this.closeTimeout = setTimeout(() => {
      this.syncHiddenToInput()
      this.closeList()
    }, 100)
  }

  choose (event) {
    const button = event.target.closest('button[data-value]')
    if (!button) return

    event.preventDefault()
    this.setValue({
      label: button.dataset.label,
      value: button.dataset.value
    })
    this.closeList()
  }

  renderList (items) {
    this.listTarget.innerHTML = ''

    if (items.length === 0) {
      const empty = document.createElement('div')
      empty.className = 'px-3 py-2 text-xs text-gray-500'
      empty.textContent = 'No matches'
      this.listTarget.appendChild(empty)
      return
    }

    items.forEach(option => {
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'block w-full text-left px-3 py-2 text-xs text-gray-700 hover:bg-gray-100'
      button.dataset.value = option.value
      button.dataset.label = option.label
      button.textContent = option.label
      this.listTarget.appendChild(button)
    })
  }

  openList () {
    this.listTarget.hidden = false
  }

  closeList () {
    this.listTarget.hidden = true
  }

  syncHiddenToInput () {
    const query = this.inputTarget.value.trim().toLowerCase()
    if (!query) {
      this.hiddenTarget.value = ''
      return
    }

    const match = this.allOptions.find(option => option.label.toLowerCase() === query)
    if (match) {
      this.hiddenTarget.value = match.value
    } else {
      this.hiddenTarget.value = ''
    }
  }

  setValue ({ label, value }) {
    this.inputTarget.value = label
    this.hiddenTarget.value = value
  }

  normalizeOptions (options) {
    const normalized = options.map(([label, value]) => ({
      label: String(label),
      value: value == null ? '' : String(value)
    }))

    normalized.unshift({ label: 'Unassigned', value: '' })
    return normalized
  }
}
