# Database health check for test environment
module DatabaseHealthCheck
  def self.wait_for_connection(max_retries: 30, sleep_time: 2)
    retries = 0

    loop do
      ActiveRecord::Base.connection.execute("SELECT 1")

      return true
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      retries += 1

      raise e if retries >= max_retries

      sleep sleep_time
    end
  end

  def self.prepare_test_database!
    # Check if we're in test environment
    raise "Not in test environment! Current environment: #{Rails.env}" unless Rails.env.test?

    # Wait for connection
    wait_for_connection

    # Check if database exists
    ActiveRecord::Base.connection.execute("SELECT 1")

    # Run migrations if needed
    ActiveRecord::Tasks::DatabaseTasks.migrate if ActiveRecord::Base.connection_pool.migration_context.needs_migration?
  end
end

# Run health check before test suite starts
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseHealthCheck.prepare_test_database!
  end
end
