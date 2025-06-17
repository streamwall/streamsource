FactoryBot.define do
  factory :annotation_stream do
    association :annotation
    association :stream
    association :added_by_user, factory: :user
    stream_timestamp_seconds { rand(0..3600) } # Random timestamp up to 1 hour
    relevance_score { rand(1..5) }
    stream_notes { Faker::Lorem.sentence }
    
    trait :high_relevance do
      relevance_score { 5 }
      stream_notes { 'Primary source - clear view of event' }
    end
    
    trait :low_relevance do
      relevance_score { 1 }
      stream_notes { 'Background context only' }
    end
    
    trait :with_timestamp do
      stream_timestamp_seconds { 120 } # 2 minutes
      stream_timestamp_display { '2:00' }
    end
    
    trait :without_timestamp do
      stream_timestamp_seconds { nil }
      stream_timestamp_display { nil }
    end
  end
end