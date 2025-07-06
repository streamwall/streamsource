# Puma configuration file

# Specifies the number of `workers` to boot in clustered mode.
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Min and Max threads per worker
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Production-specific configuration
if ENV.fetch("RAILS_ENV") { "development" } == "production"
  # Bind to unix socket for nginx
  bind "unix:///var/www/streamsource/shared/tmp/sockets/puma.sock"

  # Logging
  stdout_redirect "/var/www/streamsource/shared/log/puma.stdout.log",
                  "/var/www/streamsource/shared/log/puma.stderr.log",
                  true

  # Set master PID and state locations
  pidfile "/var/www/streamsource/shared/tmp/pids/puma.pid"
  state_path "/var/www/streamsource/shared/tmp/pids/puma.state"

  # Activate the control app
  activate_control_app "unix:///var/www/streamsource/shared/tmp/sockets/pumactl.sock"

  # Use the `preload_app!` method when specifying a `workers` number
  preload_app!

  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end

  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end
