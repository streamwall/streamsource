module Admin
  class IgnoreListsController < BaseController
    before_action :set_ignore_list, only: [:edit, :update, :destroy]

    def index
      @ignore_lists = IgnoreList.all

      # Filter by list type
      if params[:list_type].present?
        @ignore_lists = @ignore_lists.where(list_type: params[:list_type])
      end

      # Search functionality
      if params[:search].present?
        @ignore_lists = @ignore_lists.where('value ILIKE ?', "%#{params[:search]}%")
      end

      # Sorting
      @ignore_lists = @ignore_lists.order(created_at: :desc)

      # Pagination
      @pagy, @ignore_lists = pagy(@ignore_lists, items: 25)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def new
      @ignore_list = IgnoreList.new(list_type: params[:list_type])
    end

    def create
      @ignore_list = IgnoreList.new(ignore_list_params)

      if @ignore_list.save
        redirect_to admin_ignore_lists_path, notice: 'Ignore list entry was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @ignore_list.update(ignore_list_params)
        redirect_to admin_ignore_lists_path, notice: 'Ignore list entry was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ignore_list.destroy
      redirect_to admin_ignore_lists_path, notice: 'Ignore list entry was successfully deleted.'
    end

    # Bulk import action
    def bulk_import
      if request.post?
        results = process_bulk_import(params[:import_data], params[:list_type])
        
        if results[:errors].empty?
          redirect_to admin_ignore_lists_path, notice: "Successfully imported #{results[:created].count} entries."
        else
          redirect_to admin_ignore_lists_path, 
                      alert: "Imported #{results[:created].count} entries. #{results[:errors].count} errors occurred."
        end
      end
    end

    private

    def set_ignore_list
      @ignore_list = IgnoreList.find(params[:id])
    end

    def ignore_list_params
      params.require(:ignore_list).permit(:list_type, :value, :notes)
    end

    def process_bulk_import(import_data, list_type)
      results = { created: [], errors: [] }
      
      return results if import_data.blank? || list_type.blank?

      # Split by newlines and process each line
      import_data.split("\n").each do |line|
        value = line.strip
        next if value.blank?

        ignore_list = IgnoreList.new(list_type: list_type, value: value)
        
        if ignore_list.save
          results[:created] << ignore_list
        else
          results[:errors] << { value: value, errors: ignore_list.errors.full_messages }
        end
      end

      results
    end
  end
end