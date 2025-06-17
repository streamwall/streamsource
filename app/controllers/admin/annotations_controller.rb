module Admin
  class AnnotationsController < BaseController
    before_action :set_annotation, only: [:show, :edit, :update, :destroy, :resolve, :dismiss]
    
    def index
      @pagy, @annotations = pagy(
        Annotation.includes(:user, :resolved_by_user, :streams, :annotation_streams)
                  .filtered(filter_params)
                  .recent,
        items: 20
      )
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def show
      @annotation_streams = @annotation.annotation_streams.includes(:stream, :added_by_user).by_relevance
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def new
      @annotation = Annotation.new(event_timestamp: Time.current)
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
    
    def create
      @annotation = Annotation.new(annotation_params)
      @annotation.user = current_admin_user
      
      respond_to do |format|
        if @annotation.save
          format.html { redirect_to admin_annotations_path, notice: 'Annotation was successfully created.' }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend('annotations', partial: 'admin/annotations/annotation', locals: { annotation: @annotation }),
              turbo_stream.replace('flash', partial: 'admin/shared/flash', 
                locals: { notice: 'Annotation was successfully created.' }),
              turbo_stream.replace('new_annotation_modal', '')
            ]
          end
        else
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'annotation_form',
              partial: 'admin/annotations/form',
              locals: { annotation: @annotation }
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
        if @annotation.update(annotation_params)
          format.html { redirect_to admin_annotation_path(@annotation), notice: 'Annotation was successfully updated.' }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@annotation, partial: 'admin/annotations/annotation', locals: { annotation: @annotation }),
              turbo_stream.replace('flash', partial: 'admin/shared/flash', 
                locals: { notice: 'Annotation was successfully updated.' }),
              turbo_stream.replace("edit_annotation_#{@annotation.id}_modal", '')
            ]
          end
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'annotation_form',
              partial: 'admin/annotations/form',
              locals: { annotation: @annotation }
            )
          end
        end
      end
    end
    
    def destroy
      @annotation.destroy!
      
      respond_to do |format|
        format.html { redirect_to admin_annotations_path, notice: 'Annotation was successfully deleted.' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@annotation),
            turbo_stream.replace('flash', partial: 'admin/shared/flash', 
              locals: { notice: 'Annotation was successfully deleted.' })
          ]
        end
      end
    end
    
    def resolve
      @annotation.resolve!(current_admin_user, params[:resolution_notes])
      
      respond_to do |format|
        format.html { redirect_to admin_annotation_path(@annotation), notice: 'Annotation was marked as resolved.' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@annotation, partial: 'admin/annotations/annotation', locals: { annotation: @annotation }),
            turbo_stream.replace('flash', partial: 'admin/shared/flash', 
              locals: { notice: 'Annotation was marked as resolved.' })
          ]
        end
      end
    end
    
    def dismiss
      @annotation.dismiss!(current_admin_user, params[:dismissal_notes])
      
      respond_to do |format|
        format.html { redirect_to admin_annotation_path(@annotation), notice: 'Annotation was dismissed.' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@annotation, partial: 'admin/annotations/annotation', locals: { annotation: @annotation }),
            turbo_stream.replace('flash', partial: 'admin/shared/flash', 
              locals: { notice: 'Annotation was dismissed.' })
          ]
        end
      end
    end
    
    # Add a stream to an annotation
    def add_stream
      @annotation = Annotation.find(params[:id])
      @stream = Stream.find(params[:stream_id])
      
      @annotation.add_stream!(
        @stream,
        current_admin_user,
        timestamp_seconds: params[:timestamp_seconds],
        relevance: params[:relevance_score] || 3,
        notes: params[:stream_notes]
      )
      
      respond_to do |format|
        format.html { redirect_to admin_annotation_path(@annotation), notice: 'Stream added to annotation.' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend('annotation_streams', 
              partial: 'admin/annotations/annotation_stream', 
              locals: { annotation_stream: @annotation.annotation_streams.find_by(stream: @stream) }),
            turbo_stream.replace('flash', partial: 'admin/shared/flash', 
              locals: { notice: 'Stream added to annotation.' })
          ]
        end
      end
    end
    
    private
    
    def set_annotation
      @annotation = Annotation.find(params[:id])
    end
    
    def annotation_params
      params.require(:annotation).permit(:title, :description, :event_type, :priority_level, 
                                          :event_timestamp, :location, :latitude, :longitude,
                                          :external_url, :requires_review, :tag_list)
    end
    
    def filter_params
      params.permit(:event_type, :priority_level, :review_status, :location, :search, 
                    :requires_review, :start_date, :end_date)
    end
  end
end