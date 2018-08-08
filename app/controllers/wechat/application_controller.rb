require 'rest-client'
class Wechat::ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include SessionsHelper
  
  layout "wechat"
  protect_from_forgery with: :null_session
  # 验证请求是否来自于微信服务器
  before_filter :check_weixin_legality
  
  # 验证当前微信用户是否可用
  # before_filter :check_weixin_user
  
  # 获取微信的access token
  helper_method :fetch_wechat_access_token
  def fetch_wechat_access_token
    WX::Base.fetch_access_token
  end
  
  private 
    def check_weixin_legality
      render(text: "Forbidden", status: 403) unless Wechat::Base.check_wechat_legality(params[:timestamp], params[:nonce], params[:signature])
    end
    
    # def check_weixin_user
    #   # @weixin_user = WechatUser.from_wechat(weixin_xml)
    #   wechat_auth = WechatAuth.find_by(open_id: weixin_xml.from_user)
    #   
    #   render("weixin/403", formats: :xml) if wechat_auth.blank? or wechat_auth.user.blank? or !wechat_auth.user.verified
    # end
    
end
