# coding: utf-8
class SessionsController < Devise::SessionsController
  layout 'account'
  
  def new
    @action = "登录"
    super
  end
  
  # protected
  # 
  #   def after_sign_in_path_for(resource)
  #     if resource.account_type.blank?
  #       # 还未完善资料
  #       more_profile_path
  #     else
  #       portal_root_path
  #     end
  #   end

end