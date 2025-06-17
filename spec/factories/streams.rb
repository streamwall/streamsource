FactoryBot.define do
  factory :stream do
    sequence(:name) { |n| "Stream #{n}" }
    sequence(:url) { |n| "https://example.com/stream#{n}" }
    status { "active" }
    is_pinned { false }
    user
    
    trait :inactive do
      status { "inactive" }
    end
    
    trait :pinned do
      is_pinned { true }
    end
  end
end