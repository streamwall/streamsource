export class CellEditor {
  constructor(controller) {
    this.controller = controller
    this.autosaveTimeout = null
  }

  handleCellClick(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    const isLocked = cell.dataset.locked === 'true'
    const lockedBy = cell.dataset.lockedBy
    const field = cell.dataset.field
    const fieldType = cell.dataset.fieldType
    
    // Prevent editing if locked by another user
    if (isLocked && lockedBy !== this.controller.currentUser) {
      this.controller.messageDisplayManager.showLockedMessage(cell)
      return
    }
    
    // Request lock
    this.controller.actionCableManager.perform('lock_cell', { cell_id: cellId })
    
    // Handle select fields differently
    if (fieldType === 'select') {
      this.controller.cellRenderer.showSelectDropdown(cell)
    } else {
      // Make cell editable
      cell.contentEditable = true
      cell.focus()
      
      // Select all text
      const range = document.createRange()
      range.selectNodeContents(cell)
      const sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
    }
    
    // Set edit timeout (30 seconds)
    this.controller.editTimeoutManager.setEditTimeout(cellId)
  }

  handleCellBlur(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    const field = cell.dataset.field
    
    // Clear any pending autosave to prevent duplicate saves
    if (this.autosaveTimeout) {
      clearTimeout(this.autosaveTimeout)
      this.autosaveTimeout = null
    }
    
    // Check if we should skip saving (e.g., Escape was pressed)
    if (cell.dataset.skipSave !== 'true') {
      // Save changes
      this.saveCell(cell)
      // Note: saveCell will handle unlocking
    } else {
      // Just unlock without saving
      this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
      delete cell.dataset.skipSave
    }
    
    // Make cell non-editable
    cell.contentEditable = false
    
    // Clear edit timeout
    this.controller.editTimeoutManager.clearEditTimeout(cellId)
  }

  handleCellInput(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    
    // Reset edit timeout on input
    this.controller.editTimeoutManager.clearEditTimeout(cellId)
    this.controller.editTimeoutManager.setEditTimeout(cellId)
    
    // Debounced autosave
    clearTimeout(this.autosaveTimeout)
    this.autosaveTimeout = setTimeout(() => {
      this.saveCell(cell)
    }, 1000)
  }

  handleCellKeydown(event) {
    const cell = event.currentTarget
    
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      cell.blur()
    } else if (event.key === 'Escape') {
      event.preventDefault()
      // Restore original value
      const originalValue = cell.dataset.originalValue || ''
      cell.textContent = originalValue
      // Don't save changes
      cell.dataset.skipSave = 'true'
      cell.blur()
    } else if (event.key === 'Tab') {
      event.preventDefault()
      // Save current cell
      cell.blur()
      
      // Find next/previous editable cell
      const allCells = this.controller.cellTargets
      const currentIndex = allCells.indexOf(cell)
      let nextIndex
      
      if (event.shiftKey) {
        // Shift+Tab: go to previous cell
        nextIndex = currentIndex - 1
        if (nextIndex < 0) nextIndex = allCells.length - 1
      } else {
        // Tab: go to next cell
        nextIndex = currentIndex + 1
        if (nextIndex >= allCells.length) nextIndex = 0
      }
      
      // Click on the next cell to edit it
      if (allCells[nextIndex]) {
        allCells[nextIndex].click()
      }
    }
  }

  saveCell(cell) {
    const cellId = cell.dataset.cellId
    const streamId = cell.dataset.streamId
    const field = cell.dataset.field
    const value = cell.textContent.trim()
    const originalValue = cell.dataset.originalValue || ''
    
    console.log('saveCell called for field:', field, 'with value:', value)
    
    // Validate required data
    if (!cellId || !streamId || !field) {
      console.error('Missing required data for cell save:', { cellId, streamId, field })
      return
    }
    
    // Validate cell is still in correct position
    const td = cell.closest('td')
    const tr = td ? td.closest('tr') : null
    if (!td || !tr) {
      console.error('Cell is not in a valid table structure!', { cellId })
      return
    }
    
    // Only save if value changed
    if (value !== originalValue) {
      console.log('Saving cell:', { cellId, streamId, field, value, originalValue })
      
      this.controller.actionCableManager.perform('update_cell', {
        cell_id: cellId,
        stream_id: streamId,
        field: field,
        value: value
      })
      
      // Update original value
      cell.dataset.originalValue = value
    } else {
      console.log('No change detected, not saving:', { value, originalValue })
    }
    
    // Unlock cell
    this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
  }
}