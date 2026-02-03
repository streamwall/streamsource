import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['column', 'columnToggle', 'scrollContainer']
  static values = {
    hiddenColumns: Array,
    columnOrder: Array,
    preferencesUrl: String
  }

  connect () {
    this.hiddenColumns = Array.isArray(this.hiddenColumnsValue) ? [...this.hiddenColumnsValue] : []
    this.columnOrder = Array.isArray(this.columnOrderValue) ? [...this.columnOrderValue] : []
    if (this.columnOrder.length === 0) {
      this.columnOrder = this.defaultColumnOrder()
    }

    this.bindDragHandlers()
    this.applyColumnOrder()
    this.applyHiddenColumns()
    this.syncToggles()
    this.restoreScroll()
    this.initializeDragAndDrop()
  }

  disconnect () {
    clearTimeout(this.saveTimeout)
    this.headerCells().forEach(cell => {
      cell.removeEventListener('dragstart', this.boundHandleDragStart)
      cell.removeEventListener('dragover', this.boundHandleDragOver)
      cell.removeEventListener('drop', this.boundHandleDrop)
      cell.removeEventListener('dragend', this.boundHandleDragEnd)
    })
  }

  toggleColumn (event) {
    const column = event.target.value
    if (!column) return

    if (event.target.checked) {
      this.hiddenColumns = this.hiddenColumns.filter(entry => entry !== column)
    } else if (!this.hiddenColumns.includes(column)) {
      this.hiddenColumns = [...this.hiddenColumns, column]
    }

    this.applyHiddenColumns()
    this.scheduleSave()
  }

  rememberScroll () {
    if (!this.hasScrollContainerTarget) return

    try {
      sessionStorage.setItem('streamsTableScrollLeft', this.scrollContainerTarget.scrollLeft)
    } catch (error) {
      this.reportError('Failed to store scroll position', error)
    }
  }

  reorderColumns (draggedColumn, targetColumn) {
    const currentOrder = this.columnOrder.slice()
    const draggedIndex = currentOrder.indexOf(draggedColumn)
    const targetIndex = currentOrder.indexOf(targetColumn)

    if (draggedIndex === -1 || targetIndex === -1) return
    if (draggedIndex === targetIndex) return

    currentOrder.splice(draggedIndex, 1)
    currentOrder.splice(targetIndex, 0, draggedColumn)
    this.columnOrder = currentOrder
    this.applyColumnOrder()
    this.persistColumnOrder()
  }

  applyColumnOrder () {
    const order = this.columnOrder.length > 0 ? this.columnOrder : this.defaultColumnOrder()
    const headerRow = this.headerRow()
    if (headerRow) this.reorderRow(headerRow, order)

    this.bodyRows().forEach(row => {
      this.reorderRow(row, order)
    })
  }

  applyHiddenColumns () {
    const hidden = new Set(this.hiddenColumns)
    this.columnTargets.forEach(element => {
      const column = element.dataset.column
      if (!column) return

      if (hidden.has(column)) {
        element.classList.add('hidden')
      } else {
        element.classList.remove('hidden')
      }
    })
  }

  syncToggles () {
    const hidden = new Set(this.hiddenColumns)
    this.columnToggleTargets.forEach(toggle => {
      toggle.checked = !hidden.has(toggle.value)
    })
  }

  scheduleSave () {
    if (!this.hasPreferencesUrlValue) return

    clearTimeout(this.saveTimeout)
    this.saveTimeout = setTimeout(() => this.persistHiddenColumns(), 250)
  }

  persistHiddenColumns () {
    this.persistPreferences({
      hidden_columns: this.hiddenColumns,
      column_order: this.columnOrder
    })
  }

  persistColumnOrder () {
    this.persistPreferences({
      hidden_columns: this.hiddenColumns,
      column_order: this.columnOrder
    })
  }

  persistPreferences (payload) {
    if (!this.hasPreferencesUrlValue) return

    fetch(this.preferencesUrlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      credentials: 'same-origin',
      body: JSON.stringify(payload)
    }).catch(error => {
      this.reportError('Failed to save column preferences', error)
    })
  }

  restoreScroll () {
    if (!this.hasScrollContainerTarget) return

    let storedValue
    try {
      storedValue = sessionStorage.getItem('streamsTableScrollLeft')
    } catch (error) {
      this.reportError('Failed to read scroll position', error)
      return
    }

    if (!storedValue) return

    const scrollLeft = Number.parseInt(storedValue, 10)
    if (Number.isNaN(scrollLeft)) return

    requestAnimationFrame(() => {
      this.scrollContainerTarget.scrollLeft = scrollLeft
    })

    try {
      sessionStorage.removeItem('streamsTableScrollLeft')
    } catch (error) {
      this.reportError('Failed to clear scroll position', error)
    }
  }

  initializeDragAndDrop () {
    this.headerCells().forEach(cell => {
      cell.setAttribute('draggable', 'true')
      cell.classList.add('cursor-move')
      cell.title = 'Drag to reorder'
      cell.addEventListener('dragstart', this.boundHandleDragStart)
      cell.addEventListener('dragover', this.boundHandleDragOver)
      cell.addEventListener('drop', this.boundHandleDrop)
      cell.addEventListener('dragend', this.boundHandleDragEnd)
    })
  }

  bindDragHandlers () {
    this.boundHandleDragStart = this.handleDragStart.bind(this)
    this.boundHandleDragOver = this.handleDragOver.bind(this)
    this.boundHandleDrop = this.handleDrop.bind(this)
    this.boundHandleDragEnd = this.handleDragEnd.bind(this)
  }

  handleDragStart (event) {
    const column = event.currentTarget.dataset.column
    if (!column) return

    this.draggedColumn = column
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', column)
    event.currentTarget.classList.add('opacity-50')
  }

  handleDragOver (event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  handleDrop (event) {
    event.preventDefault()
    const targetColumn = event.currentTarget.dataset.column
    if (!this.draggedColumn || !targetColumn) return

    this.reorderColumns(this.draggedColumn, targetColumn)
  }

  handleDragEnd (event) {
    event.currentTarget.classList.remove('opacity-50')
    this.draggedColumn = null
  }

  defaultColumnOrder () {
    return this.headerCells().map(cell => cell.dataset.column).filter(Boolean)
  }

  headerRow () {
    return this.element.querySelector('thead tr')
  }

  bodyRows () {
    return Array.from(this.element.querySelectorAll('tbody tr'))
  }

  headerCells () {
    return Array.from(this.element.querySelectorAll('thead th[data-column]'))
  }

  reorderRow (row, order) {
    const cellsByKey = {}
    row.querySelectorAll('[data-column]').forEach(cell => {
      cellsByKey[cell.dataset.column] = cell
    })

    order.forEach(column => {
      const cell = cellsByKey[column]
      if (cell) row.appendChild(cell)
    })
  }

  csrfToken () {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  reportError (message, error) {
    this.element.dispatchEvent(new CustomEvent('stream-table-preferences:error', {
      detail: { message, error },
      bubbles: true
    }))
  }
}
