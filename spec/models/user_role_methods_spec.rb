require 'rails_helper'

RSpec.describe User, 'role methods', type: :model do
  describe '#editor?' do
    it 'returns true for editor role' do
      user = build(:user, role: 'editor')
      expect(user.editor?).to be true
    end
    
    it 'returns false for other roles' do
      expect(build(:user, role: 'default').editor?).to be false
      expect(build(:user, role: 'admin').editor?).to be false
    end
  end
  
  describe '#default?' do
    it 'returns true for default role' do
      user = build(:user, role: 'default')
      expect(user.default?).to be true
    end
    
    it 'returns false for other roles' do
      expect(build(:user, role: 'editor').default?).to be false
      expect(build(:user, role: 'admin').default?).to be false
    end
  end
  
  describe '#admin?' do
    it 'returns true for admin role' do
      user = build(:user, role: 'admin')
      expect(user.admin?).to be true
    end
    
    it 'returns false for other roles' do
      expect(build(:user, role: 'default').admin?).to be false
      expect(build(:user, role: 'editor').admin?).to be false
    end
  end
end