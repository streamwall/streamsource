module Admin
  class UsersController < BaseController
    def index
      @pagy, @users = pagy(User.all.order(:email))
    end
  end
end