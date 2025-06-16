class ApplicationController < ActionController::API
  include JwtAuthenticatable
end