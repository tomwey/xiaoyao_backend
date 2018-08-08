# coding: utf-8
class AccountController < Devise::RegistrationsController
  protect_from_forgery with: :exception
  
  layout :layout_by_action
  def layout_by_action
    if %w(edit update).include?(action_name)
      "user_layout"
    elsif %w(new create more_profile).include?(action_name)
      "account"
    end
  end
  
  def new
    @action = "注册"
    super
  end
  
  def create
    code = params[:merchant][:code]
    
    # 删掉不需要的参数
    sign_up_params.delete(:code)
    sign_up_params.delete(:email)
    
    build_resource(sign_up_params)
    
    valid = resource.valid?
    # ac = AuthCode.where('mobile = ? and code = ? and verified = ?', resource.mobile, code, true).first
    auth_code = AuthCode.check_code_for(resource.mobile, code)
    if auth_code.blank?
      resource.errors.add(:code, "不正确的验证码")
      valid = false
    end
    
    if valid && resource.save
      auth_code.active
      
      if resource.active_for_authentication?        
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)#redirect_location(resource_name, resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?#:inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      # puts resource.errors.full_messages
      render :new
    end
  end
  
  def edit
    @user = current_user
    
    if params[:by] == 'pwd'
      set_seo_meta("修改密码")
      @current = 'user_edit_pwd'
    else
      set_seo_meta("修改基本资料")
      @current = 'user_edit_profile'
    end
    
    
    # 首次生成用户 Token
    # @user.update_private_token if @user.private_token.blank?
  end
  
  def update
    super
  end
  
end