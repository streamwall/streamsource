FactoryBot.define do
  factory :streamer do
    association :user
    name { Faker::Internet.unique.username(separators: ['_']) }
    bio { Faker::Lorem.paragraph(sentence_count: 2) }
    status { 'active' }
    is_featured { false }
    notes { Faker::Lorem.sentence }
    
    trait :featured do
      is_featured { true }
    end
    
    trait :inactive do
      status { 'inactive' }
    end
    
    trait :banned do
      status { 'banned' }
    end
    
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
        create(:stream, streamer: streamer, status: 'Live')
      end
    end
  end
end