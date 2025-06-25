export class CellEditor {
  constructor(controller) {
    this.controller = controller
    this.autosaveTimeout = null
    this.savingCells = new Set() // Track cells being saved
    this.lockedCells = new Set() // Track cells we've locked
  }

  handleCellClick(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    const isLocked = cell.dataset.locked === 'true'
    const lockedBy = cell.dataset.lockedBy
    const field = cell.dataset.field
    const fieldType = cell.dataset.fieldType
    
    // Prevent editing if cell is being saved
    if (this.savingCells.has(cellId)) {
      console.log('Cell is being saved, ignoring click')
      return
    }
    
    // Prevent editing if locked by another user
    if (isLocked && lockedBy !== this.controller.currentUser) {
      this.controller.messageDisplayManager.showLockedMessage(cell)
      return
    }
    
    // Request lock
    this.lockCell(cellId)
    
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
    
    // Don't process blur if cell is already non-editable (prevents double processing)
    if (cell.contentEditable === 'false') {
      return
    }
    
    // Clear any pending autosave to prevent duplicate saves
    if (this.autosaveTimeout) {
      clearTimeout(this.autosaveTimeout)
      this.autosaveTimeout = null
    }
    
    // Make cell non-editable immediately to prevent race conditions
    cell.contentEditable = false
    
    // Check if we should skip saving (e.g., Escape was pressed)
    if (cell.dataset.skipSave !== 'true') {
      // Save changes
      this.saveCell(cell)
      // Note: saveCell will handle unlocking
    } else {
      // Just unlock without saving
      this.unlockCell(cellId)
      delete cell.dataset.skipSave
    }
    
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
    
    // Mark cell as being saved
    this.savingCells.add(cellId)
    
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
      // Note: update_cell will automatically unlock the cell on the server
      
      // Clear saving flag after a short delay to allow server response
      setTimeout(() => {
        this.savingCells.delete(cellId)
      }, 500)
    } else {
      console.log('No change detected, not saving:', { value, originalValue })
      // Only unlock if we didn't save (since update_cell auto-unlocks)
      this.unlockCell(cellId)
      
      // Clear saving flag immediately since we're not actually saving
      this.savingCells.delete(cellId)
    }
  }

  lockCell(cellId) {
    if (!this.lockedCells.has(cellId)) {
      this.lockedCells.add(cellId)
      this.controller.actionCableManager.perform('lock_cell', { cell_id: cellId })
      return true
    }
    return false
  }

  unlockCell(cellId) {
    if (this.lockedCells.has(cellId)) {
      this.lockedCells.delete(cellId)
      this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
      return true
    }
    return false
  }

  // Called when we receive confirmation that a cell was unlocked
  confirmCellUnlocked(cellId) {
    this.lockedCells.delete(cellId)
    this.savingCells.delete(cellId)
  }
}