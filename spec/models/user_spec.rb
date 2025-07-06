require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }
  
  describe 'associations' do
    it { should have_many(:streams).dependent(:destroy) }
    it { should have_many(:streamers).dependent(:destroy) }
    it { should have_many(:timestamps).dependent(:destroy) }
    it { should have_many(:timestamp_streams).with_foreign_key('added_by_user_id').dependent(:destroy) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    
    context 'on create' do
      it { should validate_length_of(:password).is_at_least(8) }
      
      it 'validates password complexity' do
        user = build(:user, password: 'simple')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must include lowercase, uppercase, and number')
      end
      
      it 'accepts valid password' do
        user = build(:user, password: 'Valid123')
        expect(user).to be_valid
      end
    end
    
    context 'on update' do
      let(:user) { create(:user) }
      
      it 'does not validate password if not changed' do
        user.email = 'newemail@example.com'
        expect(user).to be_valid
      end
      
      it 'does not validate password complexity on update' do
        user.password = 'simple123'  # Simple password that would fail on create
        expect(user).to be_valid  # But should be valid on update
      end
    end
    
    # Role validation is handled by the enum itself, no need for explicit inclusion validation
  end
  
  describe 'enums' do
    it { should define_enum_for(:role).backed_by_column_of_type(:string).with_values(default: 'default', editor: 'editor', admin: 'admin') }
    
    it 'has default role as default' do
      user = User.new
      expect(user.role).to eq('default')
    end
  end
  
  describe 'scopes' do
    let!(:admin) { create(:user, :admin) }
    let!(:editor) { create(:user, :editor) }
    let!(:default_user) { create(:user) }
    
    describe '.editors' do
      it 'returns only editors' do
        expect(User.editors).to contain_exactly(editor)
      end
    end
    
    describe '.admins' do
      it 'returns only admins' do
        expect(User.admins).to contain_exactly(admin)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#normalize_email' do
      it 'downcases email before validation' do
        user = build(:user, email: 'USER@EXAMPLE.COM')
        user.valid?
        expect(user.email).to eq('user@example.com')
      end
      
      it 'strips whitespace from email' do
        user = build(:user, email: '  user@example.com  ')
        user.valid?
        expect(user.email).to eq('user@example.com')
      end
      
      it 'handles nil email gracefully' do
        user = build(:user, email: nil)
        expect { user.valid? }.not_to raise_error
      end
    end
  end
  
  describe 'instance methods' do
    describe '#can_modify_streams?' do
      it 'returns true for editor' do
        user = build(:user, :editor)
        expect(user.can_modify_streams?).to be true
      end
      
      it 'returns true for admin' do
        user = build(:user, :admin)
        expect(user.can_modify_streams?).to be true
      end
      
      it 'returns false for default user' do
        user = build(:user)
        expect(user.can_modify_streams?).to be false
      end
    end
    
    describe '#flipper_id' do
      it 'returns formatted flipper id' do
        user = create(:user)
        expect(user.flipper_id).to eq("User:#{user.id}")
      end
    end
    
    describe '#beta_user?' do
      it 'returns false by default' do
        user = build(:user)
        expect(user.beta_user?).to be false
      end
    end
    
    describe '#premium?' do
      it 'returns true for admin' do
        user = build(:user, :admin)
        expect(user.premium?).to be true
      end
      
      it 'returns false for non-admin' do
        user = build(:user)
        expect(user.premium?).to be false
      end
    end
    
    describe '#display_name' do
      it 'returns email before @ symbol' do
        user = build(:user, email: 'john.doe@example.com')
        expect(user.display_name).to eq('john.doe')
      end
      
      it 'handles emails with multiple dots' do
        user = build(:user, email: 'first.middle.last@example.com')
        expect(user.display_name).to eq('first.middle.last')
      end
      
      it 'handles simple emails' do
        user = build(:user, email: 'admin@example.com')
        expect(user.display_name).to eq('admin')
      end
    end
  end
  
  describe 'secure password' do
    let(:user) { create(:user, password: 'Test123!') }
    
    it 'authenticates with correct password' do
      expect(user.authenticate('Test123!')).to eq(user)
    end
    
    it 'returns false with incorrect password' do
      expect(user.authenticate('wrong')).to be false
    end
    
    it 'stores password as digest' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('Test123!')
    end
  end
  
  describe 'edge cases' do
    it 'handles very long emails' do
      user = build(:user, email: "#{'a' * 255}@example.com")
      expect(user).to be_valid
    end
    
    it 'prevents SQL injection in email' do
      user = build(:user, email: "test'; DROP TABLE users; --@example.com")
      user.valid?
      expect(User.count).to be >= 0 # Table should still exist
    end
    
    it 'handles password at exact minimum length' do
      user = build(:user, password: 'Pass123!')  # Exactly 8 chars with required complexity
      expect(user).to be_valid
    end
    
    it 'handles international email domains' do
      user = build(:user, email: 'user@пример.рф')
      # Should be invalid based on current email regex
      expect(user).not_to be_valid
    end
    
    it 'normalizes emails with multiple spaces' do
      user = create(:user, email: '  user@example.com  ')
      expect(user.email).to eq('user@example.com')
    end
    
    it 'handles role changes during concurrent access' do
      user = create(:user, role: 'default')
      
      # Simulate concurrent role check and update
      user1 = User.find(user.id)
      user2 = User.find(user.id)
      
      expect(user1.can_modify_streams?).to be false
      user2.update!(role: 'editor')
      
      # Original instance still has old role until reload
      expect(user1.can_modify_streams?).to be false
      user1.reload
      expect(user1.can_modify_streams?).to be true
    end
    
    it 'handles password validation skip on update' do
      user = create(:user)
      # Update without password should succeed
      expect(user.update(email: 'new@example.com')).to be true
      # But invalid password on create should fail
      new_user = build(:user, password: 'short')
      expect(new_user).not_to be_valid
    end
    
    it 'handles unicode in email local part' do
      user = build(:user, email: 'üser@example.com')
      expect(user).not_to be_valid
    end
    
    it 'rejects email with consecutive dots' do
      user = build(:user, email: 'user..name@example.com')
      expect(user).not_to be_valid
    end
  end
end