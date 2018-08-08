require 'rest-client'
class Wechat::SessionsController < Wechat::ApplicationController
  skip_before_filter :check_weixin_legality
  
  def new
    if session['wechat.code'].blank?
      # 首先去获取code
      url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(wechat_redirect_uri_url)}&response_type=code&scope=snsapi_userinfo&state=yujian_web#wechat_redirect"
      # puts url
      redirect_to(url)
    else
      # 有code直接进行登录授权操作
      # redirect("/wechat_shop/redirect?code=#{session['wechat.code']}&state=nj_shop")
      redirect_to wechat_redirect_uri_path(code: session['wechat.code'], state: 'yujian_web')
    end
  end
  
  def save_user
    if params[:code].blank?
      # flash[:notice] = '取消登录认证'
      # redirect_to(request.referrer)
      render(text: "取消登录认证", status: 401)
      return 
    end
    
    # 开始登录
    session['wechat.code'] = params[:code]
    
    resp = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token", 
                   { :params => { 
                                  :appid      => SiteConfig.wx_app_id,
                                  :secret     => SiteConfig.wx_app_secret,
                                  :grant_type => "authorization_code",
                                  :code       => params[:code]
                                } 
                   }
                   
    result = JSON.parse(resp)
    
    openid = result['openid'];
    if openid.blank?
      # flash[:error] = '无效的code，请重试'
      # redirect_to(request.referrer)
      render(text: "无效的code，请重试", status: 403)
      return 
    end
    
    user = User.from_wechat_auth(result)
    if user
      log_in user
      remember(user)
      session['wechat.code'] = nil
      redirect_back_or(nil)
    else
      # flash[:error] = '登录认证失败'
      # redirect_back_or(nil)
      render(text: "登录认证失败", status: 401)
    end
    
  end
  
  def destroy
    log_out
    render(text: "退出登录成功", status: 200)
    # redirect_back_or(nil)
  end
  
end
