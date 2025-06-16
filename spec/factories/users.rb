FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    role { "default" }
    
    trait :editor do
      role { "editor" }
    end
    
    trait :admin do
      role { "admin" }
    end
  end
end