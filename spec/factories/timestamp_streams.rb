FactoryBot.define do
  factory :timestamp_stream do
    timestamp
    stream
    added_by_user { association :user }
    stream_timestamp_seconds { 120 } # Default to 2 minutes

    trait :with_timestamp do
      stream_timestamp_seconds { 120 } # 2 minutes
      stream_timestamp_display { "2:00" }
    end

    trait :without_timestamp do
      stream_timestamp_seconds { nil }
      stream_timestamp_display { nil }
    end
  end
end
