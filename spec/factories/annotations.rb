FactoryBot.define do
  factory :annotation do
    association :user
    title { "Important Event at #{Faker::Address.city}" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    event_type { Annotation.event_types.keys.sample }
    priority_level { 'medium' }
    review_status { 'pending' }
    event_timestamp { Faker::Time.between(from: 1.week.ago, to: Time.current) }
    location { "#{Faker::Address.city}, #{Faker::Address.state_abbr}" }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    requires_review { false }
    
    trait :critical do
      priority_level { 'critical' }
      requires_review { true }
    end
    
    trait :high_priority do
      priority_level { 'high' }
    end
    
    trait :resolved do
      review_status { 'resolved' }
      resolved_at { 1.hour.ago }
      association :resolved_by_user, factory: :user
      resolution_notes { 'Event has been verified and documented' }
    end
    
    trait :dismissed do
      review_status { 'dismissed' }
      resolved_at { 1.hour.ago }
      association :resolved_by_user, factory: :user
      resolution_notes { 'False alarm - no action needed' }
    end
    
    trait :with_external_url do
      external_url { Faker::Internet.url }
    end
    
    trait :with_tags do
      after(:build) do |annotation|
        annotation.tag_list = ['breaking', 'urgent', 'verified']
      end
    end
    
    trait :emergency do
      event_type { 'emergency' }
      priority_level { 'critical' }
      requires_review { true }
    end
    
    trait :breaking_news do
      event_type { 'breaking_news' }
      priority_level { 'high' }
    end
    
    trait :with_streams do
      after(:create) do |annotation|
        create_list(:annotation_stream, 3, annotation: annotation)
      end
    end
  end
end