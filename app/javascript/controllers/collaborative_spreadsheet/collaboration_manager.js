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
        inactive: user.inactive === true,
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
      inactive: false,
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
    
    const presenceHtml = Array.from(this.activeUsers.entries()).map(([userId, user]) => {
      const suffix = [
        user.isCurrentUser ? 'You' : null,
        user.inactive ? 'Inactive' : null
      ].filter(Boolean).join(', ')
      const label = suffix.length > 0 ? `${user.name} (${suffix})` : user.name
      const safeLabel = this.escapeHtml(label)

      return `
        <div class="group relative">
          <div class="w-6 h-6 rounded-full border border-white shadow-sm ${user.inactive ? 'opacity-40' : ''}"
               style="background-color: ${user.color}"
               aria-label="${safeLabel}"></div>
          <div class="pointer-events-none absolute left-1/2 -translate-x-1/2 -top-2 -translate-y-full opacity-0 group-hover:opacity-100 transition-opacity duration-150 z-20">
            <div class="whitespace-nowrap rounded-md bg-gray-900 px-2 py-1 text-[11px] text-white shadow-lg">
              ${safeLabel}
            </div>
          </div>
        </div>
      `
    }).join('')
    
    this.controller.presenceListTarget.innerHTML = presenceHtml

    if (this.controller.hasPresenceCountTarget) {
      const activeCount = Array.from(this.activeUsers.values()).filter(user => !user.inactive).length
      this.controller.presenceCountTarget.textContent = activeCount.toString()
    }
  }

  escapeHtml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\"/g, '&quot;')
      .replace(/'/g, '&#39;')
  }
}
