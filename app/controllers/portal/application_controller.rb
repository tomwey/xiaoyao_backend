class Portal::ApplicationController < ApplicationController
  # include Pundit
  
  layout 'portal'
  
  before_filter :require_user
  before_filter :check_user
  # before_filter :require_member
  # before_filter :check_member
  # before_filter :check_more_profile
  
  # rescue_from Pundit::NotAuthorizedError, with: :unauthorized
  
  private
  
  # alias_method :pundit_user, :current_member
  
  # def unauthorized
  #   redirect_to request.referrer || portal_root_path, alert: '没有权限执行！'
  # end
  
end