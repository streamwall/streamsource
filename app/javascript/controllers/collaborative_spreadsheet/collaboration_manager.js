export class CollaborationManager {
  constructor(controller) {
    this.controller = controller
    this.activeUsers = new Map()
  }

  setActiveUsers(users) {
    // Clear existing users
    this.activeUsers.clear()
    
    // Add all users including current user
    users.forEach(user => {
      this.activeUsers.set(user.user_id.toString(), { 
        name: user.user_name, 
        color: user.user_color,
        isCurrentUser: user.user_id.toString() === this.controller.currentUser
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
      isCurrentUser: userId.toString() === this.controller.currentUser
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
    if (!this.controller.hasPresenceListTarget) return
    
    const presenceHtml = Array.from(this.activeUsers.entries()).map(([userId, user]) => `
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 rounded-full" style="background-color: ${user.color}"></div>
        <span class="text-sm ${user.isCurrentUser ? 'font-semibold' : ''}">${user.name} ${user.isCurrentUser ? '(You)' : ''}</span>
      </div>
    `).join('')
    
    this.controller.presenceListTarget.innerHTML = presenceHtml
  }
}