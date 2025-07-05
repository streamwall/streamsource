FactoryBot.define do
  factory :location do
    city { Faker::Address.city }
    state_province { Faker::Address.state_abbr }
    country { Faker::Address.country }
    
    trait :with_coordinates do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
    end
    
    trait :with_region do
      region { ['Northeast', 'Southeast', 'Midwest', 'Southwest', 'West'].sample }
    end
    
    trait :usa do
      city { Faker::Address.city }
      state_province { Faker::Address.state_abbr }
      country { 'USA' }
    end
    
    trait :international do
      city { Faker::Address.city }
      state_province { nil }
      country { Faker::Address.country }
    end
  end
end