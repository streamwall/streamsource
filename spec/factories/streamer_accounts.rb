FactoryBot.define do
  factory :streamer_account do
    association :streamer
    platform { StreamerAccount.platforms.keys.sample }
    username { Faker::Internet.unique.username(separators: ['_']) }
    profile_url { nil } # Will be auto-generated
    status { 'active' }
    is_verified { false }
    follower_count { rand(100..100000) }
    
    trait :verified do
      is_verified { true }
    end
    
    trait :suspended do
      status { 'suspended' }
    end
    
    trait :inactive do
      status { 'inactive' }
    end
    
    trait :twitch do
      platform { 'twitch' }
    end
    
    trait :youtube do
      platform { 'youtube' }
    end
    
    trait :tiktok do
      platform { 'tiktok' }
    end
    
    trait :instagram do
      platform { 'instagram' }
    end
    
    trait :with_custom_url do
      profile_url { Faker::Internet.url }
    end
    
    trait :popular do
      follower_count { rand(500000..5000000) }
      is_verified { true }
    end
  end
end