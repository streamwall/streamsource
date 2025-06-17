FactoryBot.define do
  factory :streamer_account do
    streamer
    platform { 'twitch' } # Default to a specific platform
    username { Faker::Internet.unique.username(separators: ['_']) }
    profile_url { nil } # Will be auto-generated in the model
    is_active { true }
    
    trait :inactive do
      is_active { false }
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
    
    trait :facebook do
      platform { 'facebook' }
    end
    
    trait :with_custom_url do
      profile_url { Faker::Internet.url }
    end
  end
end