# frozen_string_literal: true

module FlipperHelpers
  def enable_feature(feature, actor = nil)
    if actor
      Flipper.enable_actor(feature, actor)
    else
      Flipper.enable(feature)
    end
  end
  
  def disable_feature(feature)
    Flipper.disable(feature)
  end
  
  def enable_feature_for_group(feature, group)
    Flipper.enable_group(feature, group)
  end
  
  def enable_feature_for_percentage(feature, percentage)
    Flipper.enable_percentage_of_actors(feature, percentage)
  end
  
  def with_feature(feature, actor = nil)
    enable_feature(feature, actor)
    yield
  ensure
    disable_feature(feature)
  end
  
  def with_feature_group(feature, group)
    enable_feature_for_group(feature, group)
    yield
  ensure
    disable_feature(feature)
  end
  
  def reset_flipper
    Flipper.instance = nil
    # Clear all features from database
    if defined?(Flipper::Adapters::ActiveRecord::Feature)
      Flipper::Adapters::ActiveRecord::Feature.destroy_all
      Flipper::Adapters::ActiveRecord::Gate.destroy_all
    end
  end
end

RSpec.configure do |config|
  config.include FlipperHelpers
  
  config.before(:suite) do
    # Ensure Flipper tables exist
    unless ActiveRecord::Base.connection.table_exists?('flipper_features')
      ActiveRecord::Migration.verbose = false
      load Rails.root.join('db/migrate/20250117000001_create_flipper_tables.rb')
      CreateFlipperTables.new.up
    end
  end
  
  config.before(:each) do
    # Reset Flipper state between tests
    reset_flipper
  end
end