import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['column', 'columnToggle', 'scrollContainer', 'columnList', 'columnItem', 'columnDrag']
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
    this.isReady = true
  }

  columnTargetConnected () {
    if (!this.isReady) return
    this.scheduleApply()
  }

  disconnect () {
    clearTimeout(this.saveTimeout)
    clearTimeout(this.applyTimeout)
    this.columnItemTargets.forEach(item => {
      item.removeEventListener('pointerdown', this.boundHandlePointerDown)
      item.removeEventListener('dragover', this.boundHandleDragOver)
      item.removeEventListener('drop', this.boundHandleDrop)
    })
    this.columnDragTargets.forEach(handle => {
      handle.classList.remove('cursor-move')
    })
    if (this.hasColumnListTarget) {
      this.columnListTarget.removeEventListener('click', this.boundHandleClickSuppress, true)
    }
  }

  scheduleApply () {
    if (this.applyScheduled) return

    this.applyScheduled = true
    requestAnimationFrame(() => {
      this.applyScheduled = false
      this.applyWhenIdle()
    })
  }

  applyWhenIdle () {
    if (this.isEditing()) {
      clearTimeout(this.applyTimeout)
      this.applyTimeout = setTimeout(() => this.applyWhenIdle(), 200)
      return
    }

    this.applyColumnOrder()
    this.applyHiddenColumns()
  }

  isEditing () {
    const active = document.activeElement
    if (active && active.closest('[data-collaborative-spreadsheet-target="cell"]')) {
      return true
    }

    if (this.element.querySelector('[data-collaborative-spreadsheet-target="cell"][contenteditable="true"]')) {
      return true
    }

    const currentUserId = this.element.getAttribute('data-collaborative-spreadsheet-current-user-id-value')
    if (currentUserId) {
      const lockedByCurrentUser = this.element.querySelector(
        `[data-collaborative-spreadsheet-target="cell"][data-locked="true"][data-locked-by="${currentUserId}"]`
      )
      if (lockedByCurrentUser) return true
    }

    return false
  }

  toggleColumn (event) {
    const column = event.target.value
    if (!column) return

    if (event.target.checked) {
      this.hiddenColumns = this.hiddenColumns.filter(entry => entry !== column)
    } else if (!this.hiddenColumns.includes(column)) {
      this.hiddenColumns = [...this.hiddenColumns, column]
    }

    this.applyWhenIdle()
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
    const insertIndex = draggedIndex < targetIndex ? targetIndex - 1 : targetIndex
    currentOrder.splice(insertIndex, 0, draggedColumn)
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

    if (this.hasColumnListTarget) {
      this.reorderRow(this.columnListTarget, order)
    }
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
    this.columnItemTargets.forEach(item => {
      item.classList.add('cursor-move')
      item.addEventListener('pointerdown', this.boundHandlePointerDown)
      item.addEventListener('dragover', this.boundHandleDragOver)
      item.addEventListener('drop', this.boundHandleDrop)
    })
    this.columnDragTargets.forEach(handle => {
      handle.classList.add('cursor-move')
    })

    if (this.hasColumnListTarget) {
      this.columnListTarget.addEventListener('click', this.boundHandleClickSuppress, true)
    }
  }

  bindDragHandlers () {
    this.boundHandleDragStart = this.handleDragStart.bind(this)
    this.boundHandleDragOver = this.handleDragOver.bind(this)
    this.boundHandleDrop = this.handleDrop.bind(this)
    this.boundHandleDragEnd = this.handleDragEnd.bind(this)
    this.boundHandlePointerDown = this.handlePointerDown.bind(this)
    this.boundHandlePointerMove = this.handlePointerMove.bind(this)
    this.boundHandlePointerUp = this.handlePointerUp.bind(this)
    this.boundHandleClickSuppress = this.handleClickSuppress.bind(this)
  }

  handlePointerDown (event) {
    if (event.button !== 0) return
    if (event.target.closest('input[type="checkbox"]')) return

    const item = event.currentTarget
    const column = item.dataset.column
    if (!column) return

    this.draggedColumn = column
    this.dragSourceItem = item
    this.dragTargetItem = null
    this.dragStartX = event.clientX
    this.dragStartY = event.clientY
    this.isDragging = false
    this.pointerId = event.pointerId

    window.addEventListener('pointermove', this.boundHandlePointerMove)
    window.addEventListener('pointerup', this.boundHandlePointerUp)
  }

  handlePointerMove (event) {
    if (this.pointerId !== event.pointerId) return

    const deltaX = Math.abs(event.clientX - this.dragStartX)
    const deltaY = Math.abs(event.clientY - this.dragStartY)
    if (!this.isDragging && deltaX + deltaY < 6) return

    if (!this.isDragging) {
      this.isDragging = true
      this.dragSourceItem.classList.add('opacity-50')
      document.body.classList.add('select-none')
    }

    const target = document.elementFromPoint(event.clientX, event.clientY)
      ?.closest('[data-stream-table-preferences-target="columnItem"]')
    if (!target || target === this.dragSourceItem) return

    if (this.dragTargetItem && this.dragTargetItem !== target) {
      this.clearDropIndicator(this.dragTargetItem)
    }
    this.dragTargetItem = target
    this.applyDropIndicator(this.dragTargetItem)
  }

  handlePointerUp (event) {
    if (this.pointerId !== event.pointerId) return

    window.removeEventListener('pointermove', this.boundHandlePointerMove)
    window.removeEventListener('pointerup', this.boundHandlePointerUp)

    if (this.isDragging && this.dragTargetItem && this.dragTargetItem !== this.dragSourceItem) {
      this.suppressClick = true
      this.reorderColumns(this.draggedColumn, this.dragTargetItem.dataset.column)
    }

    if (this.dragSourceItem) {
      this.dragSourceItem.classList.remove('opacity-50')
    }
    if (this.dragTargetItem) {
      this.clearDropIndicator(this.dragTargetItem)
    }

    document.body.classList.remove('select-none')

    this.draggedColumn = null
    this.dragSourceItem = null
    this.dragTargetItem = null
    this.isDragging = false
    this.pointerId = null
  }

  applyDropIndicator (item) {
    if (!item) return
    item.classList.add('relative')
    item.style.boxShadow = 'inset 0 2px 0 0 rgb(99 102 241)'
  }

  clearDropIndicator (item) {
    if (!item) return
    item.style.boxShadow = ''
  }

  handleClickSuppress (event) {
    if (!this.suppressClick) return
    event.preventDefault()
    event.stopPropagation()
    this.suppressClick = false
  }

  handleDragStart (event) {
    event.preventDefault()
  }

  handleDragOver (event) {
    event.preventDefault()
  }

  handleDrop (event) {
    event.preventDefault()
  }

  handleDragEnd (event) {
    event.preventDefault()
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
