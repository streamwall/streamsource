export class MessageDisplayManager {
  constructor(controller) {
    this.controller = controller
    this.connectionStatusElement = null
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

  showConnectionStatus(status) {
    // Remove existing status element if any
    if (this.connectionStatusElement) {
      this.connectionStatusElement.remove()
      this.connectionStatusElement = null
    }
    
    // Don't show connected status (only show problems)
    if (status === 'connected') {
      return
    }
    
    // Create status element
    const statusElement = document.createElement('div')
    statusElement.className = 'fixed bottom-4 right-4 px-4 py-2 rounded shadow-lg text-white text-sm z-50'
    
    if (status === 'disconnected') {
      statusElement.className += ' bg-red-600'
      statusElement.textContent = 'Disconnected from server - attempting to reconnect...'
    } else if (status === 'rejected') {
      statusElement.className += ' bg-red-800'
      statusElement.textContent = 'Connection rejected - please refresh the page'
    }
    
    document.body.appendChild(statusElement)
    this.connectionStatusElement = statusElement
    
    // Auto-remove disconnected message after 5 seconds
    if (status === 'disconnected') {
      setTimeout(() => {
        if (this.connectionStatusElement === statusElement) {
          statusElement.remove()
          this.connectionStatusElement = null
        }
      }, 5000)
    }
  }
}