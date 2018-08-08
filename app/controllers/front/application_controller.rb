class Front::ApplicationController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include SessionsHelper
  
  private
  def require_user    
    if current_user.blank?

      ua = request.user_agent
      is_wx_browser = ua.include?('MicroMessenger') || ua.include?('webbrowser')

      if is_wx_browser
        # puts '是微信浏览器'
        url = request.original_url

        redirect_url  = "#{SiteConfig.wx_auth_redirect_uri}?url=#{url}&provider=wechat"#"#{wechat_auth_redirect_url}?url=#{request.original_url}"

        @wx_auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&response_type=code&scope=snsapi_userinfo&state=redpack#wechat_redirect"
        redirect_to @wx_auth_url
      else
        # puts '不是微信浏览器'
        url = request.original_url
        
        redirect_url = "#{SiteConfig.wx_auth_redirect_uri}?url=#{url}&provider=qq"
        # puts redirect_url
        @qq_auth_url = "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=#{SiteConfig.qq_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&scope=get_user_info"
        # puts @qq_auth_url
        redirect_to @qq_auth_url
        # redirect_to "#{wechat_entry_help_url}"
      end
    end
  end

  
end
