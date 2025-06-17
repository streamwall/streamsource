require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }
  
  describe 'associations' do
    it { should have_many(:streams).dependent(:destroy) }
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
      
      it 'validates password if changed' do
        user.password = 'simple'
        expect(user).not_to be_valid
      end
    end
    
    it { should validate_inclusion_of(:role).in_array(%w[default editor admin]) }
  end
  
  describe 'enums' do
    it { should define_enum_for(:role).with_values(default: 'default', editor: 'editor', admin: 'admin') }
    
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
  end
end