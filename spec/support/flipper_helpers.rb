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
  
  def initialize_all_features
    # Initialize all features from ApplicationConstants::Features
    ApplicationConstants::Features.constants.each do |const|
      feature_name = ApplicationConstants::Features.const_get(const)
      
      begin
        Flipper.add(feature_name.to_s)
      rescue Flipper::FeatureNameExists
        # Feature already exists, which is fine
      end
    end
  end
end

RSpec.configure do |config|
  config.include FlipperHelpers
  
  config.before(:suite) do
    begin
      # Wait for database connection to be ready
      retries = 0
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        retries += 1
        if retries < 10
          puts "Waiting for database in Flipper setup... (attempt #{retries}/10)"
          sleep 1
          retry
        else
          raise e
        end
      end
      
      # Ensure Flipper tables exist
      unless ActiveRecord::Base.connection.table_exists?('flipper_features')
        ActiveRecord::Migration.verbose = false
        migration_file = Rails.root.join('db/migrate/20250117000001_create_flipper_tables.rb')
        if File.exist?(migration_file)
          load migration_file
          CreateFlipperTables.new.up
        else
          # If migration doesn't exist, create tables manually
          ActiveRecord::Base.connection.create_table :flipper_features do |t|
            t.string :key, null: false
            t.timestamps null: false
          end
          ActiveRecord::Base.connection.add_index :flipper_features, :key, unique: true
          
          ActiveRecord::Base.connection.create_table :flipper_gates do |t|
            t.string :feature_key, null: false
            t.string :key, null: false
            t.text :value
            t.timestamps null: false
          end
          ActiveRecord::Base.connection.add_index :flipper_gates, [:feature_key, :key], unique: true
        end
      end
      
      # Initialize all features from ApplicationConstants
      ApplicationConstants::Features.constants.each do |const|
        feature_name = ApplicationConstants::Features.const_get(const)
        
        begin
          Flipper.add(feature_name.to_s)
        rescue Flipper::FeatureNameExists
          # Feature already exists, which is fine
        end
      end
    rescue => e
      puts "Error in Flipper setup: #{e.message}"
      puts e.backtrace.first(5)
      # Don't fail the entire test suite if Flipper setup fails
    end
  end
  
  config.before(:each) do
    # Reset Flipper state between tests
    reset_flipper if defined?(Flipper)
    # Re-initialize all features to ensure clean state
    initialize_all_features if defined?(Flipper)
  end
end