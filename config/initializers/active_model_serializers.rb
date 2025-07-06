ActiveModelSerializers.config.adapter = :json
ActiveModelSerializers.config.default_includes = "**"

# Configure time format to match Rails default JSON format
ActiveSupport::JSON::Encoding.time_precision = 3
