FactoryBot.define do
  factory :note do
    association :user
    content { Faker::Lorem.paragraph(sentence_count: 2) }
    
    # Default to stream as notable
    association :notable, factory: :stream
    
    trait :for_stream do
      association :notable, factory: :stream
    end
    
    trait :for_streamer do
      association :notable, factory: :streamer
    end
    
    trait :for_annotation do
      association :notable, factory: :annotation
    end
    
    trait :long do
      content { Faker::Lorem.paragraph(sentence_count: 10) }
    end
    
    trait :short do
      content { Faker::Lorem.sentence }
    end
  end
end