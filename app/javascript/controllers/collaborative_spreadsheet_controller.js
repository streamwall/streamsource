import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["cell", "userIndicator", "presenceList"]
  
  connect() {
    this.currentUser = this.data.get("currentUserId")
    this.currentUserName = this.data.get("currentUserName")
    this.currentUserColor = this.data.get("currentUserColor")
    this.editTimeouts = new Map()
    this.activeUsers = new Map()
    
    console.log('Collaborative spreadsheet initialized', {
      cellCount: this.cellTargets.length,
      currentUser: this.currentUser
    })
    
    // Connect to ActionCable
    this.subscription = createConsumer().subscriptions.create("CollaborativeStreamsChannel", {
      received: (data) => this.handleMessage(data),
      connected: () => console.log("Connected to CollaborativeStreamsChannel"),
      disconnected: () => console.log("Disconnected from CollaborativeStreamsChannel")
    })
    
    // Set up cell event listeners
    this.cellTargets.forEach(cell => {
      cell.addEventListener('click', this.handleCellClick.bind(this))
      cell.addEventListener('blur', this.handleCellBlur.bind(this))
      cell.addEventListener('input', this.handleCellInput.bind(this))
      cell.addEventListener('keydown', this.handleCellKeydown.bind(this))
    })
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    
    // Clear any edit timeouts
    this.editTimeouts.forEach(timeout => clearTimeout(timeout))
  }
  
  handleMessage(data) {
    switch(data.action) {
      case 'active_users_list':
        // Received when first connecting - show all active users
        this.setActiveUsers(data.users)
        break
      case 'user_joined':
        this.addUser(data.user_id, data.user_name, data.user_color)
        break
      case 'user_left':
        this.removeUser(data.user_id)
        break
      case 'cell_locked':
        this.showCellLocked(data.cell_id, data.user_id, data.user_name, data.user_color)
        break
      case 'cell_unlocked':
        this.hideCellLocked(data.cell_id)
        break
      case 'cell_updated':
        this.updateCell(data.cell_id, data.field, data.value, data.stream_id)
        break
    }
  }
  
  handleCellClick(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    const isLocked = cell.dataset.locked === 'true'
    const lockedBy = cell.dataset.lockedBy
    const field = cell.dataset.field
    
    // Prevent editing if locked by another user
    if (isLocked && lockedBy !== this.currentUser) {
      this.showLockedMessage(cell)
      return
    }
    
    // For status field and other fields with special formatting, 
    // replace content with plain text for editing
    if (field === 'status') {
      const currentValue = cell.dataset.originalValue || cell.textContent.trim()
      cell.textContent = currentValue
    }
    
    // Make cell editable
    cell.contentEditable = true
    cell.focus()
    
    // Select all text
    const range = document.createRange()
    range.selectNodeContents(cell)
    const sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(range)
    
    // Request lock
    this.subscription.perform('lock_cell', { cell_id: cellId })
    
    // Set edit timeout (30 seconds)
    this.setEditTimeout(cellId)
  }
  
  handleCellBlur(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    const field = cell.dataset.field
    
    // Check if we should skip saving (e.g., Escape was pressed)
    if (cell.dataset.skipSave !== 'true') {
      // Save changes
      this.saveCell(cell)
    } else {
      // Just unlock without saving
      this.subscription.perform('unlock_cell', { cell_id: cellId })
      delete cell.dataset.skipSave
    }
    
    // Make cell non-editable
    cell.contentEditable = false
    
    // For status field, restore the formatted display with current value
    if (field === 'status') {
      const value = cell.dataset.originalValue || cell.textContent.trim()
      const colorClass = value === 'Live' ? 'bg-green-100 text-green-800' : 
                        value === 'Offline' ? 'bg-red-100 text-red-800' : 
                        'bg-gray-100 text-gray-800'
      // Clear content first, then add span
      while (cell.firstChild) {
        cell.removeChild(cell.firstChild)
      }
      const span = document.createElement('span')
      span.className = `px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colorClass}`
      span.textContent = value
      cell.appendChild(span)
    }
    
    // Clear edit timeout
    this.clearEditTimeout(cellId)
  }
  
  handleCellInput(event) {
    const cell = event.currentTarget
    const cellId = cell.dataset.cellId
    
    // Reset edit timeout on input
    this.clearEditTimeout(cellId)
    this.setEditTimeout(cellId)
    
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
      const allCells = this.cellTargets
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
      
      this.subscription.perform('update_cell', {
        cell_id: cellId,
        stream_id: streamId,
        field: field,
        value: value
      })
      
      // Update original value
      cell.dataset.originalValue = value
    }
    
    // Unlock cell
    this.subscription.perform('unlock_cell', { cell_id: cellId })
  }
  
  showCellLocked(cellId, userId, userName, userColor) {
    const cell = this.cellTargets.find(c => c.dataset.cellId === cellId)
    if (!cell) return
    
    // Mark as locked
    cell.dataset.locked = 'true'
    cell.dataset.lockedBy = userId
    
    // Add visual indicator
    cell.style.outline = `2px solid ${userColor}`
    cell.style.outlineOffset = '-2px'
    
    // Add user indicator as a pseudo-element by adding a data attribute
    // that CSS can use, or add it to the parent TD
    const td = cell.closest('td')
    if (td) {
      // Remove any existing indicator
      const existingIndicator = td.querySelector('.user-indicator')
      if (existingIndicator) existingIndicator.remove()
      
      // Add user indicator inside the TD but outside the cell div
      const indicator = document.createElement('div')
      indicator.className = 'user-indicator absolute -top-5 left-0 px-2 py-0.5 text-xs text-white rounded shadow-sm z-10 pointer-events-none'
      indicator.style.backgroundColor = userColor
      indicator.textContent = userName
      indicator.dataset.userId = userId
      indicator.dataset.forCell = cellId
      
      td.appendChild(indicator)
    }
  }
  
  hideCellLocked(cellId) {
    const cell = this.cellTargets.find(c => c.dataset.cellId === cellId)
    if (!cell) return
    
    // Remove locked status
    cell.dataset.locked = 'false'
    delete cell.dataset.lockedBy
    
    // Remove visual indicator
    cell.style.outline = ''
    cell.style.outlineOffset = ''
    
    // Remove user indicator from TD
    const td = cell.closest('td')
    if (td) {
      const indicator = td.querySelector(`[data-for-cell="${cellId}"]`)
      if (indicator) {
        indicator.remove()
      }
    }
  }
  
  updateCell(cellId, field, value, streamId) {
    const cell = this.cellTargets.find(c => c.dataset.cellId === cellId)
    if (!cell) {
      console.error('Cell not found for update:', cellId)
      return
    }
    
    // Don't update if this user is currently editing
    if (cell.contentEditable === 'true') return
    
    console.log('Updating cell:', { cellId, field, value, currentContent: cell.textContent })
    
    // Store parent structure to ensure we don't break it
    const parentTd = cell.parentElement
    const parentTr = parentTd ? parentTd.parentElement : null
    
    // Update cell content based on field type
    if (field === 'status') {
      const colorClass = value === 'Live' ? 'bg-green-100 text-green-800' : 
                        value === 'Offline' ? 'bg-red-100 text-red-800' : 
                        'bg-gray-100 text-gray-800'
      // Clear content first, then add span
      while (cell.firstChild) {
        cell.removeChild(cell.firstChild)
      }
      const span = document.createElement('span')
      span.className = `px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colorClass}`
      span.textContent = value
      cell.appendChild(span)
    } else {
      cell.textContent = value
    }
    
    // Always update the original value data attribute
    cell.dataset.originalValue = value
    
    // Verify structure wasn't broken
    if (cell.parentElement !== parentTd || (parentTd && parentTd.parentElement !== parentTr)) {
      console.error('Table structure was broken during update!', { cellId, field })
    }
    
    // Flash update animation
    cell.classList.add('bg-green-50')
    setTimeout(() => {
      cell.classList.remove('bg-green-50')
    }, 500)
  }
  
  setActiveUsers(users) {
    // Clear existing users
    this.activeUsers.clear()
    
    // Add all users including current user
    users.forEach(user => {
      this.activeUsers.set(user.user_id.toString(), { 
        name: user.user_name, 
        color: user.user_color,
        isCurrentUser: user.user_id.toString() === this.currentUser
      })
    })
    
    // Update presence list
    this.updatePresenceList()
  }
  
  addUser(userId, userName, userColor) {
    // Add user to active users (including current user)
    this.activeUsers.set(userId.toString(), { 
      name: userName, 
      color: userColor,
      isCurrentUser: userId.toString() === this.currentUser
    })
    
    // Update presence list
    this.updatePresenceList()
  }
  
  removeUser(userId) {
    // Remove from active users
    this.activeUsers.delete(userId.toString())
    
    // Update presence list
    this.updatePresenceList()
  }
  
  updatePresenceList() {
    if (!this.hasPresenceListTarget) return
    
    const presenceHtml = Array.from(this.activeUsers.entries()).map(([userId, user]) => `
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full" style="background-color: ${user.color}"></div>
        <span class="text-sm ${user.isCurrentUser ? 'font-semibold' : ''}">${user.name} ${user.isCurrentUser ? '(You)' : ''}</span>
      </div>
    `).join('')
    
    this.presenceListTarget.innerHTML = presenceHtml
  }
  
  setEditTimeout(cellId) {
    // Clear existing timeout
    this.clearEditTimeout(cellId)
    
    // Set new timeout (30 seconds)
    const timeout = setTimeout(() => {
      const cell = this.cellTargets.find(c => c.dataset.cellId === cellId)
      if (cell && cell.contentEditable === 'true') {
        cell.blur()
        this.showTimeoutMessage(cell)
      }
    }, 30000)
    
    this.editTimeouts.set(cellId, timeout)
  }
  
  clearEditTimeout(cellId) {
    const timeout = this.editTimeouts.get(cellId)
    if (timeout) {
      clearTimeout(timeout)
      this.editTimeouts.delete(cellId)
    }
  }
  
  showLockedMessage(cell) {
    const message = document.createElement('div')
    message.className = 'absolute top-full left-0 mt-1 px-3 py-2 bg-gray-800 text-white text-sm rounded shadow-lg z-20 pointer-events-none'
    message.textContent = 'This cell is being edited by another user'
    
    // Add message to the TD element
    const td = cell.closest('td')
    if (td) {
      message.dataset.messageFor = cell.dataset.cellId
      td.appendChild(message)
      
      setTimeout(() => {
        message.remove()
      }, 2000)
    }
  }
  
  showTimeoutMessage(cell) {
    const message = document.createElement('div')
    message.className = 'absolute top-full left-0 mt-1 px-3 py-2 bg-yellow-600 text-white text-sm rounded shadow-lg z-20 pointer-events-none'
    message.textContent = 'Edit timeout - changes saved'
    
    // Add message to the TD element
    const td = cell.closest('td')
    if (td) {
      message.dataset.messageFor = cell.dataset.cellId
      td.appendChild(message)
      
      setTimeout(() => {
        message.remove()
      }, 2000)
    }
  }
}