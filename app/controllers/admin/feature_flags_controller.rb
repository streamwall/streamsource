module Admin
  class FeatureFlagsController < BaseController
    def index
      @feature_flags = get_all_feature_flags
    end

    def update
      feature_name = params[:id]
      action = params[:action_type]

      case action
      when "enable"
        Flipper.enable(feature_name)
        flash[:notice] = "Feature '#{feature_name}' has been enabled."
      when "disable"
        Flipper.disable(feature_name)
        flash[:notice] = "Feature '#{feature_name}' has been disabled."
      else
        flash[:alert] = "Invalid action."
      end

      redirect_to admin_feature_flags_path
    rescue StandardError => e
      flash[:alert] = "Error updating feature flag: #{e.message}"
      redirect_to admin_feature_flags_path
    end

    private

    def get_all_feature_flags
      # Get all defined feature flags from ApplicationConstants
      flags = []

      ApplicationConstants::Features.constants.each do |const|
        feature_name = ApplicationConstants::Features.const_get(const)
        flags << {
          name: feature_name,
          constant: const.to_s,
          enabled: Flipper.enabled?(feature_name),
          description: get_feature_description(feature_name),
        }
      end

      flags.sort_by { |f| f[:name] }
    end

    def get_feature_description(feature_name)
      descriptions = {
        "stream_analytics" => "Enable advanced analytics for streams",
        "stream_export" => "Allow exporting stream data",
        "advanced_search" => "Enable advanced search functionality",
        "stream_bulk_import" => "Allow bulk importing of streams",
        "stream_tags" => "Enable tagging system for streams",
        "ai_stream_recommendations" => "AI-powered stream recommendations",
        "maintenance_mode" => "Put the application in maintenance mode",
      }

      descriptions[feature_name] || "No description available"
    end
  end
end
