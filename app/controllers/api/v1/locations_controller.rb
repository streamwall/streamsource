module Api
  module V1
    # API endpoints for location data.
    class LocationsController < BaseController
      before_action :authenticate_user!
      before_action :set_location, only: %i[show update destroy]

      # GET /api/v1/locations
      def index
        @pagy, @locations = pagy(filtered_locations)

        render json: {
          locations: @locations.map { |location| LocationSerializer.new(location).as_json },
          meta: pagy_metadata(@pagy),
        }
      end

      # GET /api/v1/locations/all
      # Returns all locations without pagination for client-side validation
      def all
        @locations = Location.ordered.select(:id, :city, :state_province, :country, :normalized_name, :is_known_city)

        # Cache this response for 5 minutes
        expires_in 5.minutes, public: true

        render json: {
          locations: @locations.map do |loc|
            {
              id: loc.id,
              city: loc.city,
              state_province: loc.state_province,
              country: loc.country,
              display_name: loc.display_name,
              normalized_name: loc.normalized_name,
              is_known_city: loc.is_known_city,
            }
          end,
        }
      end

      # GET /api/v1/locations/known_cities
      # Returns only known/verified cities for validation
      def known_cities
        @locations = Location.known_cities.ordered.select(:id, :city, :state_province, :country, :normalized_name)

        # Cache this response for 15 minutes
        expires_in 15.minutes, public: true

        render json: {
          locations: @locations.map do |loc|
            {
              id: loc.id,
              city: loc.city,
              state_province: loc.state_province,
              country: loc.country,
              display_name: loc.display_name,
              normalized_name: loc.normalized_name,
            }
          end,
        }
      end

      # GET /api/v1/locations/:id
      def show
        render json: @location, serializer: LocationSerializer
      end

      # POST /api/v1/locations
      def create
        @location = Location.new(location_params)

        if @location.save
          render json: @location, serializer: LocationSerializer, status: :created
        else
          render json: { error: "Validation failed", details: @location.errors }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/locations/:id
      def update
        if @location.update(location_params)
          render json: @location, serializer: LocationSerializer
        else
          render json: { error: "Validation failed", details: @location.errors }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/locations/:id
      def destroy
        if @location.streams.exists?
          render json: {
            error: "Cannot delete location",
            details: { base: ["Location is being used by #{@location.streams.count} stream(s)"] },
          }, status: :unprocessable_content
        else
          @location.destroy
          head :no_content
        end
      end

      private

      def set_location
        @location = Location.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      end

      def location_params
        params.expect(location: %i[city state_province region country latitude longitude is_known_city])
      end

      def filtered_locations
        filters = {
          search: :search,
          country: :by_country,
          state: :by_state,
        }

        filters.reduce(Location.all) do |scope, (param_key, scope_method)|
          value = params[param_key]
          value.present? ? scope.public_send(scope_method, value) : scope
        end.ordered
      end
    end
  end
end
