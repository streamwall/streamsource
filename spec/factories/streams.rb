FactoryBot.define do
  factory :stream do
    user
    streamer { nil }
    source { Faker::Internet.username }
    link { Faker::Internet.url(host: 'tiktok.com') }
    title { Faker::Lorem.sentence }
    platform { 'tiktok' }
    status { 'Unknown' }
    kind { 'video' }
    orientation { 'vertical' }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    is_pinned { false }
    is_archived { false }
    started_at { nil }
    ended_at { nil }
    last_live_at { nil }
    notes { Faker::Lorem.sentence }
    posted_by { nil } # Will be set from user.email by model callback
    
    trait :live do
      status { 'Live' }
      started_at { 30.minutes.ago }
      last_live_at { Time.current }
    end
    
    trait :offline do
      status { 'Offline' }
      last_live_at { 2.hours.ago }
    end
    
    trait :archived do
      is_archived { true }
      status { 'Offline' }
      started_at { 3.hours.ago }
      ended_at { 1.hour.ago }
    end
    
    trait :pinned do
      is_pinned { true }
    end
    
    trait :with_streamer do
      association :streamer
    end
    
    trait :tiktok do
      platform { 'TikTok' }
      orientation { 'vertical' }
      link { Faker::Internet.url(host: 'tiktok.com') }
    end
    
    trait :youtube do
      platform { 'YouTube' }
      orientation { 'horizontal' }
      link { Faker::Internet.url(host: 'youtube.com') }
    end
    
    trait :twitch do
      platform { 'Twitch' }
      orientation { 'horizontal' }
      link { Faker::Internet.url(host: 'twitch.tv') }
    end
    
    trait :facebook do
      platform { 'Facebook' }
      orientation { 'horizontal' }
      link { Faker::Internet.url(host: 'facebook.com') }
    end
    
    trait :instagram do
      platform { 'Instagram' }
      orientation { 'vertical' }
      link { Faker::Internet.url(host: 'instagram.com') }
    end
  end
end