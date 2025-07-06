# frozen_string_literal: true

# Database health check for test environment
module DatabaseHealthCheck
  def self.wait_for_connection(max_retries: 30, sleep_time: 2)
    retries = 0

    loop do
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "Database connection established!"
      return true
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      retries += 1

      if retries >= max_retries
        puts "Failed to connect to database after #{max_retries} attempts"
        raise e
      end

      puts "Waiting for database connection... (attempt #{retries}/#{max_retries})"
      sleep sleep_time
    end
  end

  def self.ensure_test_database
    # Check if we're in test environment
    raise "Not in test environment! Current environment: #{Rails.env}" unless Rails.env.test?

    # Wait for connection
    wait_for_connection

    # Check if database exists
    ActiveRecord::Base.connection.execute("SELECT 1")

    # Run migrations if needed
    if ActiveRecord::Base.connection_pool.migration_context.needs_migration?
      puts "Running pending migrations..."
      ActiveRecord::Tasks::DatabaseTasks.migrate
    end

    puts "Test database is ready!"
    true
  rescue StandardError => e
    puts "Error setting up test database: #{e.message}"
    puts e.backtrace.first(5)
    raise e
  end
end

# Run health check before test suite starts
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseHealthCheck.ensure_test_database
  end
end
