class Offerwall::ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  layout "offerwall"
  protect_from_forgery with: :null_session
  
end
