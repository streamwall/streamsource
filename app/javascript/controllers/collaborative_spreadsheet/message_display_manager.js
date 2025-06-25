export class MessageDisplayManager {
  constructor(controller) {
    this.controller = controller
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