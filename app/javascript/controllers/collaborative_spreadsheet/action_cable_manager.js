import { createConsumer } from "@rails/actioncable"

export class ActionCableManager {
  constructor(controller) {
    this.controller = controller
    this.subscription = null
  }

  connect() {
    this.subscription = createConsumer().subscriptions.create("CollaborativeStreamsChannel", {
      received: (data) => this.handleMessage(data),
      connected: () => {
        console.log("Connected to CollaborativeStreamsChannel")
        this.controller.messageDisplayManager.showConnectionStatus('connected')
      },
      disconnected: () => {
        console.log("Disconnected from CollaborativeStreamsChannel")
        this.controller.messageDisplayManager.showConnectionStatus('disconnected')
      },
      rejected: () => {
        console.error("Connection to CollaborativeStreamsChannel was rejected")
        this.controller.messageDisplayManager.showConnectionStatus('rejected')
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  perform(action, data) {
    if (this.subscription && this.subscription.consumer.connection.isOpen()) {
      try {
        this.subscription.perform(action, data)
      } catch (error) {
        console.error(`Failed to perform action ${action}:`, error)
        this.controller.messageDisplayManager.showConnectionStatus('disconnected')
      }
    } else {
      console.warn(`Cannot perform action ${action} - not connected`)
      this.controller.messageDisplayManager.showConnectionStatus('disconnected')
    }
  }

  handleMessage(data) {
    switch(data.action) {
      case 'active_users_list':
        this.controller.collaborationManager.setActiveUsers(data.users)
        break
      case 'user_joined':
        this.controller.collaborationManager.addUser(data.user_id, data.user_name, data.user_color)
        break
      case 'user_left':
        this.controller.collaborationManager.removeUser(data.user_id)
        break
      case 'cell_locked':
        this.controller.cellRenderer.showCellLocked(data.cell_id, data.user_id, data.user_name, data.user_color)
        break
      case 'cell_unlocked':
        this.controller.cellRenderer.hideCellLocked(data.cell_id)
        // If this was our lock, update our tracking
        if (data.user_id == this.controller.currentUser) {
          this.controller.cellEditor.confirmCellUnlocked(data.cell_id)
        }
        break
      case 'cell_updated':
        this.controller.cellRenderer.updateCell(data.cell_id, data.field, data.value, data.stream_id)
        break
      case 'stream_updated':
        // Handle updates to non-editable fields like last_checked_at and last_live_at
        if (data.last_checked_at !== undefined) {
          this.controller.cellRenderer.updateTimeAgoField(data.stream_id, 'last_checked_at', data.last_checked_at)
        }
        if (data.last_live_at !== undefined) {
          this.controller.cellRenderer.updateTimeAgoField(data.stream_id, 'last_live_at', data.last_live_at)
        }
        break
    }
  }
}