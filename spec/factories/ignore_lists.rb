FactoryBot.define do
  factory :ignore_list do
    list_type { 'url' }
    value { Faker::Internet.url }
    notes { Faker::Lorem.sentence }

    trait :twitch_user do
      list_type { 'twitch_user' }
      value { Faker::Internet.username(specifier: 3..25, separators: ['_']) }
    end

    trait :discord_user do
      list_type { 'discord_user' }
      value { "#{Faker::Internet.username}##{Faker::Number.number(digits: 4)}" }
    end

    trait :url do
      list_type { 'url' }
      value { Faker::Internet.url }
    end

    trait :domain do
      list_type { 'domain' }
      value { Faker::Internet.domain_name }
    end
  end
end