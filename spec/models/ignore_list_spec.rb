require 'rails_helper'

RSpec.describe IgnoreList, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:list_type) }
    it { should validate_presence_of(:value) }
    
    it 'validates inclusion of list_type' do
      expect(IgnoreList::LIST_TYPES).to eq(%w[twitch_user discord_user url domain])
      should validate_inclusion_of(:list_type).in_array(IgnoreList::LIST_TYPES)
    end

    it 'validates uniqueness of value scoped to list_type' do
      create(:ignore_list, list_type: 'twitch_user', value: 'testuser')
      duplicate = build(:ignore_list, list_type: 'twitch_user', value: 'testuser')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:value]).to include('has already been taken')
    end

    it 'allows same value for different list types' do
      create(:ignore_list, list_type: 'twitch_user', value: 'testuser')
      different_type = build(:ignore_list, list_type: 'discord_user', value: 'testuser')
      expect(different_type).to be_valid
    end
  end

  describe 'scopes' do
    before do
      create(:ignore_list, list_type: 'twitch_user', value: 'twitchuser1')
      create(:ignore_list, list_type: 'discord_user', value: 'discorduser1')
      create(:ignore_list, list_type: 'url', value: 'https://example.com')
      create(:ignore_list, list_type: 'domain', value: 'spam.com')
    end

    it 'returns twitch users' do
      expect(IgnoreList.twitch_users.count).to eq(1)
      expect(IgnoreList.twitch_users.first.value).to eq('twitchuser1')
    end

    it 'returns discord users' do
      expect(IgnoreList.discord_users.count).to eq(1)
      expect(IgnoreList.discord_users.first.value).to eq('discorduser1')
    end

    it 'returns urls' do
      expect(IgnoreList.urls.count).to eq(1)
      expect(IgnoreList.urls.first.value).to eq('https://example.com')
    end

    it 'returns domains' do
      expect(IgnoreList.domains.count).to eq(1)
      expect(IgnoreList.domains.first.value).to eq('spam.com')
    end
  end

  describe 'value normalization' do
    context 'for twitch users' do
      it 'downcases and strips whitespace' do
        ignore_list = create(:ignore_list, list_type: 'twitch_user', value: '  TestUser  ')
        expect(ignore_list.value).to eq('testuser')
      end
    end

    context 'for discord users' do
      it 'downcases and strips whitespace' do
        ignore_list = create(:ignore_list, list_type: 'discord_user', value: '  DiscordUser#1234  ')
        expect(ignore_list.value).to eq('discorduser#1234')
      end
    end

    context 'for urls' do
      it 'adds https protocol if missing' do
        ignore_list = create(:ignore_list, list_type: 'url', value: 'example.com/path')
        expect(ignore_list.value).to eq('https://example.com/path')
      end

      it 'keeps existing protocol' do
        ignore_list = create(:ignore_list, list_type: 'url', value: 'http://example.com')
        expect(ignore_list.value).to eq('http://example.com')
      end

      it 'removes trailing slashes' do
        ignore_list = create(:ignore_list, list_type: 'url', value: 'https://example.com///')
        expect(ignore_list.value).to eq('https://example.com')
      end

      it 'handles complex URLs' do
        ignore_list = create(:ignore_list, list_type: 'url', value: '  https://example.com/path/?query=1  ')
        expect(ignore_list.value).to eq('https://example.com/path/?query=1')
      end
    end

    context 'for domains' do
      it 'downcases and removes www prefix' do
        ignore_list = create(:ignore_list, list_type: 'domain', value: '  WWW.Example.COM  ')
        expect(ignore_list.value).to eq('example.com')
      end

      it 'handles subdomains correctly' do
        ignore_list = create(:ignore_list, list_type: 'domain', value: 'subdomain.example.com')
        expect(ignore_list.value).to eq('subdomain.example.com')
      end
    end
  end
end