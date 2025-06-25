export class CellRenderer {
  constructor(controller) {
    this.controller = controller
  }

  showCellLocked(cellId, userId, userName, userColor) {
    const cell = this.controller.cellTargets.find(c => c.dataset.cellId === cellId)
    if (!cell) return
    
    console.log('showCellLocked', { cellId, userId, userName, currentUser: this.controller.currentUser })
    
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
    const cell = this.controller.cellTargets.find(c => c.dataset.cellId === cellId)
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
    const cell = this.controller.cellTargets.find(c => c.dataset.cellId === cellId)
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
      this.formatStatusCell(cell, value)
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

  formatStatusCell(cell, value = null) {
    const displayValue = value || cell.dataset.originalValue || cell.textContent.trim()
    const colorClass = displayValue === 'Live' ? 'bg-green-100 text-green-800' : 
                      displayValue === 'Offline' ? 'bg-red-100 text-red-800' : 
                      'bg-gray-100 text-gray-800'
    // Clear content first, then add span
    while (cell.firstChild) {
      cell.removeChild(cell.firstChild)
    }
    const span = document.createElement('span')
    span.className = `px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colorClass}`
    span.textContent = displayValue
    cell.appendChild(span)
  }

  updateTimeAgoField(streamId, field, timeValue) {
    const elementId = `stream_${streamId}_${field}`
    const element = document.getElementById(elementId)
    if (!element) {
      console.warn(`Time field element not found: ${elementId}`)
      return
    }
    
    // Update the time display
    if (timeValue) {
      const date = new Date(timeValue)
      const now = new Date()
      const diffSeconds = Math.floor((now - date) / 1000)
      
      let timeAgo = ''
      if (diffSeconds < 60) {
        timeAgo = 'less than a minute ago'
      } else if (diffSeconds < 3600) {
        const minutes = Math.floor(diffSeconds / 60)
        timeAgo = `${minutes} ${minutes === 1 ? 'minute' : 'minutes'} ago`
      } else if (diffSeconds < 86400) {
        const hours = Math.floor(diffSeconds / 3600)
        timeAgo = `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`
      } else {
        const days = Math.floor(diffSeconds / 86400)
        timeAgo = `${days} ${days === 1 ? 'day' : 'days'} ago`
      }
      
      element.textContent = timeAgo
    } else {
      element.textContent = 'Never'
    }
    
    // Flash update animation
    element.classList.add('bg-green-50')
    setTimeout(() => {
      element.classList.remove('bg-green-50')
    }, 500)
  }

  showSelectDropdown(cell) {
    const cellId = cell.dataset.cellId
    const field = cell.dataset.field
    let currentValue = cell.dataset.originalValue || cell.textContent.trim()
    
    // For status field, get the actual value from the span
    if (field === 'status') {
      const span = cell.querySelector('span')
      if (span) {
        currentValue = span.textContent.trim()
      }
    }
    
    const selectOptions = JSON.parse(cell.dataset.selectOptions || '{}')
    
    // Create dropdown container
    const dropdown = document.createElement('div')
    dropdown.className = 'absolute left-0 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50'
    dropdown.style.zIndex = '50'
    
    // Position it just below the cell
    const cellRect = cell.getBoundingClientRect()
    const tdRect = cell.closest('td').getBoundingClientRect()
    dropdown.style.top = `${cellRect.height + 2}px`
    
    // Create options list
    const optionsList = document.createElement('div')
    optionsList.className = 'py-1'
    optionsList.setAttribute('role', 'menu')
    
    // Add options
    Object.entries(selectOptions).forEach(([value, label]) => {
      const option = document.createElement('button')
      option.className = `block w-full text-left px-4 py-2 text-sm ${
        value === currentValue 
          ? 'bg-indigo-100 text-indigo-900 font-medium' 
          : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
      } transition-colors duration-150 ease-in-out`
      option.textContent = label
      option.dataset.value = value
      option.setAttribute('role', 'menuitem')
      
      // Add icon for current selection
      if (value === currentValue) {
        const iconSpan = document.createElement('span')
        iconSpan.className = 'absolute inset-y-0 right-0 flex items-center pr-4'
        iconSpan.innerHTML = `
          <svg class="h-5 w-5 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        `
        option.style.position = 'relative'
        option.appendChild(iconSpan)
      }
      
      optionsList.appendChild(option)
    })
    
    dropdown.appendChild(optionsList)
    
    // Position the dropdown
    const td = cell.closest('td')
    if (!td) return
    
    // Make TD relative for absolute positioning
    const originalPosition = td.style.position
    td.style.position = 'relative'
    
    // Add dropdown to TD
    td.appendChild(dropdown)
    
    // Check if dropdown would go off screen and adjust if needed
    const dropdownRect = dropdown.getBoundingClientRect()
    const viewportHeight = window.innerHeight
    
    if (dropdownRect.bottom > viewportHeight) {
      // Position above the cell instead
      dropdown.style.top = 'auto'
      dropdown.style.bottom = `${cellRect.height + 2}px`
    }
    
    // Focus first option
    const firstOption = optionsList.querySelector('button')
    if (firstOption) firstOption.focus()
    
    // Flag to track if change handler already processed
    let changeHandled = false
    
    // Handle option click
    const handleOptionClick = (event) => {
      const button = event.target.closest('button')
      if (!button) return
      
      const newValue = button.dataset.value
      changeHandled = true
      
      console.log('Select changed:', { newValue, currentValue, originalValue: cell.dataset.originalValue })
      
      // Update cell display but NOT the originalValue yet
      // Let saveCell handle updating originalValue after successful save
      if (field === 'status') {
        this.formatStatusCell(cell, newValue)
      } else {
        cell.textContent = newValue
      }
      
      // Save the change
      this.controller.cellEditor.saveCell(cell)
      
      // Clean up
      dropdown.remove()
      td.style.position = originalPosition
      
      // Clear edit timeout
      this.controller.editTimeoutManager.clearEditTimeout(cellId)
    }
    
    // Handle clicks outside the dropdown
    const handleOutsideClick = (event) => {
      if (!dropdown.contains(event.target) && event.target !== cell) {
        // Clean up without saving
        dropdown.remove()
        td.style.position = originalPosition
        
        // Unlock cell
        this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
        
        // Clear edit timeout
        this.controller.editTimeoutManager.clearEditTimeout(cellId)
        
        // Remove the event listener
        document.removeEventListener('click', handleOutsideClick)
      }
    }
    
    // Handle keyboard navigation
    const handleKeydown = (event) => {
      const options = Array.from(optionsList.querySelectorAll('button'))
      const currentIndex = options.indexOf(document.activeElement)
      
      if (event.key === 'Escape') {
        event.preventDefault()
        // Close without saving
        dropdown.remove()
        td.style.position = originalPosition
        
        // Unlock cell
        this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
        
        // Clear edit timeout
        this.controller.editTimeoutManager.clearEditTimeout(cellId)
        
        document.removeEventListener('click', handleOutsideClick)
      } else if (event.key === 'ArrowDown') {
        event.preventDefault()
        const nextIndex = currentIndex + 1 < options.length ? currentIndex + 1 : 0
        options[nextIndex].focus()
      } else if (event.key === 'ArrowUp') {
        event.preventDefault()
        const prevIndex = currentIndex - 1 >= 0 ? currentIndex - 1 : options.length - 1
        options[prevIndex].focus()
      } else if (event.key === 'Enter' && currentIndex >= 0) {
        event.preventDefault()
        options[currentIndex].click()
      } else if (event.key === 'Tab') {
        event.preventDefault()
        // Close dropdown and move to next cell
        dropdown.remove()
        td.style.position = originalPosition
        
        // Unlock cell
        this.controller.actionCableManager.perform('unlock_cell', { cell_id: cellId })
        
        // Clear edit timeout
        this.controller.editTimeoutManager.clearEditTimeout(cellId)
        
        document.removeEventListener('click', handleOutsideClick)
        
        // Move to next cell
        const allCells = this.controller.cellTargets
        const cellIndex = allCells.indexOf(cell)
        let nextIndex
        
        if (event.shiftKey) {
          nextIndex = cellIndex - 1
          if (nextIndex < 0) nextIndex = allCells.length - 1
        } else {
          nextIndex = cellIndex + 1
          if (nextIndex >= allCells.length) nextIndex = 0
        }
        
        if (allCells[nextIndex]) {
          allCells[nextIndex].click()
        }
      }
    }
    
    // Add event listeners
    optionsList.addEventListener('click', handleOptionClick)
    dropdown.addEventListener('keydown', handleKeydown)
    
    // Listen for clicks outside to close the dropdown
    setTimeout(() => {
      document.addEventListener('click', handleOutsideClick)
    }, 0)
    
    // Set edit timeout
    this.controller.editTimeoutManager.setEditTimeout(cellId)
  }
}