export class EditTimeoutManager {
  constructor(controller) {
    this.controller = controller
    this.editTimeouts = new Map()
    this.TIMEOUT_DURATION = 30000 // 30 seconds
  }

  setEditTimeout(cellId) {
    // Clear existing timeout
    this.clearEditTimeout(cellId)
    
    // Set new timeout
    const timeout = setTimeout(() => {
      const cell = this.controller.cellTargets.find(c => c.dataset.cellId === cellId)
      if (cell && cell.contentEditable === 'true') {
        cell.blur()
        this.controller.messageDisplayManager.showTimeoutMessage(cell)
      }
    }, this.TIMEOUT_DURATION)
    
    this.editTimeouts.set(cellId, timeout)
  }

  clearEditTimeout(cellId) {
    const timeout = this.editTimeouts.get(cellId)
    if (timeout) {
      clearTimeout(timeout)
      this.editTimeouts.delete(cellId)
    }
  }

  clearAllTimeouts() {
    this.editTimeouts.forEach(timeout => clearTimeout(timeout))
    this.editTimeouts.clear()
  }
}