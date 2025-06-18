module Admin
  class NotesController < BaseController
    before_action :set_notable
    before_action :set_note, only: [:show, :edit, :update, :destroy]
    
    def index
      @notes = @notable.note_records.includes(:user).recent
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def show
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def new
      @note = @notable.note_records.build
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def create
      @note = @notable.note_records.build(note_params)
      @note.user = current_admin_user
      
      respond_to do |format|
        if @note.save
          format.html { redirect_to notable_path, notice: 'Note was successfully created.' }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("#{@notable.class.name.downcase}_notes", partial: 'admin/notes/note', locals: { note: @note }),
              turbo_stream.replace('flash', partial: 'admin/shared/flash', 
                locals: { notice: 'Note was successfully created.' }),
              turbo_stream.replace('new_note_modal', '')
            ]
          end
        else
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'note_form',
              partial: 'admin/notes/form',
              locals: { note: @note, notable: @notable }
            )
          end
        end
      end
    end
    
    def edit
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def update
      respond_to do |format|
        if @note.update(note_params)
          format.html { redirect_to notable_path, notice: 'Note was successfully updated.' }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@note, partial: 'admin/notes/note', locals: { note: @note }),
              turbo_stream.replace('flash', partial: 'admin/shared/flash', 
                locals: { notice: 'Note was successfully updated.' }),
              turbo_stream.replace("edit_note_#{@note.id}_modal", '')
            ]
          end
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'note_form',
              partial: 'admin/notes/form',
              locals: { note: @note, notable: @notable }
            )
          end
        end
      end
    end
    
    def destroy
      @note.destroy!
      
      respond_to do |format|
        format.html { redirect_to notable_path, notice: 'Note was successfully deleted.' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@note),
            turbo_stream.replace('flash', partial: 'admin/shared/flash', 
              locals: { notice: 'Note was successfully deleted.' })
          ]
        end
      end
    end
    
    private
    
    def set_notable
      if params[:stream_id]
        @notable = Stream.find(params[:stream_id])
      elsif params[:streamer_id]
        @notable = Streamer.find(params[:streamer_id])
      else
        redirect_to admin_root_path, alert: 'Invalid resource'
      end
    end
    
    def set_note
      @note = @notable.note_records.find(params[:id])
    end
    
    def note_params
      params.require(:note).permit(:content)
    end
    
    def notable_path
      case @notable
      when Stream
        admin_stream_path(@notable)
      when Streamer
        admin_streamer_path(@notable)
      else
        admin_root_path
      end
    end
  end
end