FactoryBot.define do
  factory :streamer do
    user
    name { Faker::Internet.unique.username(separators: ['_']) }
    notes { Faker::Lorem.sentence }
    posted_by { nil } # Will be set from user.email by controller
    
    trait :with_accounts do
      after(:create) do |streamer|
        create(:streamer_account, :twitch, streamer: streamer)
        create(:streamer_account, :youtube, streamer: streamer)
      end
    end
    
    trait :with_streams do
      after(:create) do |streamer|
        create_list(:stream, 3, streamer: streamer)
      end
    end
    
    trait :live do
      after(:create) do |streamer|
        create(:stream, :live, streamer: streamer, user: streamer.user)
      end
    end
  end
end