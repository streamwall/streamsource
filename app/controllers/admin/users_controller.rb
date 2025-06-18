module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin]
    
    def index
      @pagy, @users = pagy(
        User.includes(:streams, :streamers, :notes)
            .order(:email)
      )
    end
    
    def show
    end
    
    def new
      @user = User.new
    end
    
    def create
      @user = User.new(user_params)
      
      if @user.save
        redirect_to admin_users_path, notice: 'User was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
    end
    
    def update
      if @user.update(update_user_params)
        redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      if @user == current_admin_user
        redirect_to admin_users_path, alert: 'You cannot delete your own account.'
      else
        @user.destroy
        redirect_to admin_users_path, notice: 'User was successfully deleted.'
      end
    end
    
    def toggle_admin
      if @user.admin?
        @user.update(role: 'default')
      else
        @user.update(role: 'admin')
      end
      
      redirect_to admin_users_path, notice: 'User role was successfully updated.'
    end
    
    private
    
    def set_user
      @user = User.find(params[:id])
    end
    
    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :role)
    end
    
    def update_user_params
      permitted = params.require(:user).permit(:email, :password, :password_confirmation, :role)
      # Remove password fields if they are blank
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
  end
end