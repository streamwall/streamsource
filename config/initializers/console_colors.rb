# Enhance Rails console with colors and formatting
# This only loads in development console sessions

if defined?(Rails::Console) && Rails.env.development?
  # Enable SQL query highlighting in console
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  
  # Load awesome_print if available for better object inspection
  begin
    require 'awesome_print'
    AwesomePrint.irb!
  rescue LoadError
    # awesome_print not available, that's okay
  end

  # Add colorized prompt
  if defined?(IRB)
    IRB.conf[:PROMPT][:RAILS] = {
      PROMPT_I: "\e[1;32m%N\e[0m(\e[1;34m%m\e[0m):\e[1;36m%03n\e[0m> ",
      PROMPT_N: "\e[1;32m%N\e[0m(\e[1;34m%m\e[0m):\e[1;36m%03n\e[0m> ",
      PROMPT_S: "\e[1;32m%N\e[0m(\e[1;34m%m\e[0m):\e[1;36m%03n\e[0m%l ",
      PROMPT_C: "\e[1;32m%N\e[0m(\e[1;34m%m\e[0m):\e[1;36m%03n\e[0m* ",
      RETURN: "=> %s\n"
    }
    IRB.conf[:PROMPT_MODE] = :RAILS
  end

  # Helper method to show colored model counts
  def model_stats
    puts "\e[1;34m=== Model Statistics ===\e[0m"
    models = [User, Stream, Streamer, StreamerAccount, Timestamp, Location]
    models.each do |model|
      count = model.count
      color = count > 0 ? "\e[1;32m" : "\e[1;33m"
      puts "#{color}#{model.name.ljust(20)}\e[0m: #{count}"
    end
    nil
  end

  # Welcome message
  puts "\e[1;35m" + "="*50 + "\e[0m"
  puts "\e[1;35mWelcome to StreamSource Rails Console!\e[0m"
  puts "\e[1;35m" + "="*50 + "\e[0m"
  puts "\e[1;33mEnvironment:\e[0m #{Rails.env}"
  puts "\e[1;33mDatabase:\e[0m #{ActiveRecord::Base.connection.current_database}"
  puts ""
  puts "\e[1;36mUseful commands:\e[0m"
  puts "  \e[0;32mmodel_stats\e[0m - Show record counts for all models"
  puts "  \e[0;32mreload!\e[0m     - Reload the console"
  puts ""
end