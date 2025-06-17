FactoryBot.define do
  factory :note do
    user
    content { Faker::Lorem.paragraph(sentence_count: 2) }
    notable { association :stream }
    
    trait :for_stream do
      notable { association :stream }
    end
    
    trait :for_streamer do
      notable { association :streamer }
    end
    
    trait :for_annotation do
      notable { association :annotation }
    end
    
    trait :long do
      content { Faker::Lorem.paragraph(sentence_count: 10) }
    end
    
    trait :short do
      content { Faker::Lorem.sentence }
    end
  end
end