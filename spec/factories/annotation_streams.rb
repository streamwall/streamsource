FactoryBot.define do
  factory :annotation_stream do
    annotation
    stream
    added_by_user { association :user }
    stream_timestamp_seconds { 120 } # Default to 2 minutes
    relevance_score { 3 } # Default to medium relevance
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