import { Controller } from '@hotwired/stimulus'
import { ActionCableManager } from './collaborative_spreadsheet/action_cable_manager'
import { CellEditor } from './collaborative_spreadsheet/cell_editor'
import { CellRenderer } from './collaborative_spreadsheet/cell_renderer'
import { CollaborationManager } from './collaborative_spreadsheet/collaboration_manager'
import { MessageDisplayManager } from './collaborative_spreadsheet/message_display_manager'
import { EditTimeoutManager } from './collaborative_spreadsheet/edit_timeout_manager'

export default class extends Controller {
  static targets = ['cell', 'userIndicator', 'presenceList']
  static values = {
    currentUserId: String,
    currentUserName: String,
    currentUserColor: String
  }

  connect () {
    this.currentUser = this.currentUserIdValue
    this.currentUserName = this.currentUserNameValue
    this.currentUserColor = this.currentUserColorValue

    // Initialize managers
    this.actionCableManager = new ActionCableManager(this)
    this.cellEditor = new CellEditor(this)
    this.cellRenderer = new CellRenderer(this)
    this.collaborationManager = new CollaborationManager(this)
    this.messageDisplayManager = new MessageDisplayManager(this)
    this.editTimeoutManager = new EditTimeoutManager(this)

    // Connect to ActionCable
    this.actionCableManager.connect()

    // Set up cell event listeners
    this.cellTargets.forEach(cell => {
      cell.addEventListener('click', this.cellEditor.handleCellClick.bind(this.cellEditor))
      cell.addEventListener('blur', this.cellEditor.handleCellBlur.bind(this.cellEditor))
      cell.addEventListener('input', this.cellEditor.handleCellInput.bind(this.cellEditor))
      cell.addEventListener('keydown', this.cellEditor.handleCellKeydown.bind(this.cellEditor))
    })
  }

  disconnect () {
    this.actionCableManager.disconnect()
    this.editTimeoutManager.clearAllTimeouts()
  }
}
