FactoryBot.define do
  factory :stream_url do
    url { "https://www.tiktok.com/@teststreamer/live" }
    url_type { 'stream' }
    platform { 'TikTok' }
    title { "Test Stream" }
    notes { "A test stream URL" }
    is_active { true }
    last_checked_at { 1.hour.ago }
    
    association :streamer
    association :created_by, factory: :user
    
    trait :permalink do
      url { "https://www.tiktok.com/@teststreamer" }
      url_type { 'permalink' }
      title { "Streamer Profile" }
    end
    
    trait :archive do
      url { "https://www.tiktok.com/@teststreamer/video/123456789" }
      url_type { 'archive' }
      title { "Past Stream Recording" }
      is_active { false }
    end
    
    trait :inactive do
      is_active { false }
    end
    
    trait :expired do
      expires_at { 1.day.ago }
    end
    
    trait :expires_soon do
      expires_at { 30.minutes.from_now }
    end
    
    trait :twitch do
      url { "https://www.twitch.tv/teststreamer" }
      platform { 'Twitch' }
    end
    
    trait :youtube do
      url { "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
      platform { 'YouTube' }
    end
    
    trait :facebook do
      url { "https://www.facebook.com/teststreamer/live" }
      platform { 'Facebook' }
    end
  end
end
