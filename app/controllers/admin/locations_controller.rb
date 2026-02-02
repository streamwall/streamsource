module Admin
  class LocationsController < Admin::BaseController
    before_action :set_location, only: %i[show edit update destroy]

    def index
      @pagy, @locations = pagy(
        Location.includes(:streams)
                .order(created_at: :desc)
                .search_by_name(params[:search]),
        limit: 25,
      )
    end

    def show
      @streams = @location.streams.includes(:streamer).order(created_at: :desc)
    end

    def new
      @location = Location.new
    end

    def edit; end

    def create
      @location = Location.new(location_params)

      respond_to do |format|
        if @location.save
          format.html { redirect_to admin_location_path(@location), notice: "Location was successfully created." }
          format.turbo_stream
        else
          format.html { render :new, status: :unprocessable_content }
          format.turbo_stream { render :form_update, status: :unprocessable_content }
        end
      end
    end

    def update
      respond_to do |format|
        if @location.update(location_params)
          format.html { redirect_to admin_location_path(@location), notice: "Location was successfully updated." }
          format.turbo_stream
        else
          format.html { render :edit, status: :unprocessable_content }
          format.turbo_stream { render :form_update, status: :unprocessable_content }
        end
      end
    end

    def destroy
      @location.destroy!

      respond_to do |format|
        format.html { redirect_to admin_locations_path, notice: "Location was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.expect(location: %i[city state_province region country latitude longitude is_known_city])
    end
  end
end
