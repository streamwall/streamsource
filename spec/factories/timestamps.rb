FactoryBot.define do
  factory :timestamp do
    user
    title { "Important Event at #{Faker::Address.city}" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    event_timestamp { 1.hour.ago }
    
    
    
    
    trait :with_streams do
      after(:create) do |timestamp|
        create_list(:timestamp_stream, 3, timestamp: timestamp)
      end
    end
  end
end