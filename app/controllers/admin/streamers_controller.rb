module Admin
  # CRUD for streamers in the admin UI.
  class StreamersController < BaseController
    before_action :set_streamer, only: %i[show edit update destroy]

    def index
      @streamers = Streamer.includes(:streamer_accounts)
                           .search(params[:search])
                           .order(created_at: :desc)
      @pagy, @streamers = pagy(@streamers)
    end

    def show
      @active_streams = @streamer.streams.active.ordered
      @archived_streams = @streamer.streams.archived.ordered.limit(10)
    end

    def new
      @streamer = current_admin_user.streamers.build
      @users = User.order(:email)
    end

    def edit
      @users = User.order(:email)
    end

    def create
      @streamer = current_admin_user.streamers.build(streamer_params)

      respond_to do |format|
        if @streamer.save
          notice = t("admin.streamers.created")
          format.html { redirect_to admin_streamer_path(@streamer), notice: notice }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("streamers", partial: "admin/streamers/streamer", locals: { streamer: @streamer }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: notice }),
              turbo_stream.replace("modal", ""),
            ]
          end
        else
          @users = User.order(:email)
          format.html { render :new, status: :unprocessable_content }
          format.turbo_stream { render :new, status: :unprocessable_content }
        end
      end
    end

    def update
      respond_to do |format|
        if @streamer.update(streamer_params)
          notice = t("admin.streamers.updated")
          format.html { redirect_to admin_streamer_path(@streamer), notice: notice }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@streamer, partial: "admin/streamers/streamer", locals: { streamer: @streamer }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: notice }),
              turbo_stream.replace("edit_streamer_modal", ""),
            ]
          end
        else
          @users = User.order(:email)
          format.html { render :edit, status: :unprocessable_content }
          format.turbo_stream { render :edit, status: :unprocessable_content }
        end
      end
    end

    def destroy
      @streamer.destroy!

      respond_to do |format|
        notice = t("admin.streamers.deleted")
        format.html { redirect_to admin_streamers_path, notice: notice }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@streamer),
            turbo_stream.replace("flash", partial: "admin/shared/flash",
                                          locals: { notice: notice }),
          ]
        end
      end
    end

    private

    def set_streamer
      @streamer = Streamer.find(params[:id])
    end

    def streamer_params
      params.expect(streamer: %i[name notes posted_by user_id])
    end
  end
end
