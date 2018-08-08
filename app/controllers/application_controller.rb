class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def access_denied(exception)
    redirect_to admin_root_path, alert: exception.message
  end
  
  # 用户注册参数白名单
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:mobile, :code, :name])
    end
    
    def current_user
      current_merchant
    end
    helper_method :current_user
    
    def authenticate_user!
      authenticate_merchant!
    end
    
    def timestamp
      @timestamp ||= Time.zone.now.to_i
    end
    helper_method :timestamp
    
    def api_access_key
      Digest::MD5.hexdigest(SiteConfig.api_key + timestamp.to_s)
    end
    helper_method :api_access_key
    
    # 需要登录
    def require_user
      if current_user.blank?
        respond_to do |format|
          format.html { authenticate_user! }
          format.all  { head(:unauthorized) }
        end
      end
    end
  
    # 检查用户账号是否被冻结
    def check_user
      unless current_user.verified
        flash[:error] = "您的账号已经被冻结"
        redirect_to portal_root_path
      end
    end
    
    # 要求实名认证
    def require_auth
      unless current_user.authed?
        flash[:error] = "您的账号还未进行实名认证"
        redirect_to portal_user_auth_path
      end
    end
    
    # 检查用户是否已经完善了资料
    # def check_more_profile
    #   if current_member.account_type.blank?
    #     redirect_to more_profile_path
    #   end
    # end
    
    # def after_sign_up_path_for(resource)
    #   # if resource.account_type.blank?
    #   #   # 还未完善资料
    #   #   more_profile_path
    #   # else
    #     portal_root_path
    #   # end
    # end
    #
    # def after_update_path_for(resource)
    #   home_user_path
    # end
    #
    # def after_sign_in_path_for(resource)
    #   if resource.class == Admin
    #     cpanel_root_path
    #   else
    #     portal_root_path
    #     # if resource.account_type.blank?
    #     #   # 还未完善资料
    #     #   return more_profile_path
    #     # else
    #     #   return portal_root_path
    #     # end
    #   end
    # end
    #
    # def after_sign_out_path_for(resource)
    #   # puts resource.to_s
    #   if resource.to_s == 'admin'
    #     new_admin_session_path
    #   else
    #     new_merchant_session_path
    #   end
    # end
  
end
