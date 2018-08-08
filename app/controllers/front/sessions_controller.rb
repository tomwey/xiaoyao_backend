require 'rest-client'
class Front::SessionsController < Front::ApplicationController
  # skip_before_filter :check_weixin_legality
  
  def app_auth
    
  end
  
  def save_user
    if params[:provider] && (params[:provider] == 'qq' || params[:provider] == 'wechat')
      from_url = params[:from_url] || SiteConfig.front_url
      if from_url.include? '?'
        url = "#{from_url}&code=#{params[:code]}&provider=#{params[:provider]}"
      else
        url = "#{from_url}?code=#{params[:code]}&provider=#{params[:provider]}"
      end
      
      redirect_to url
      
      # redirect_to("#{SiteConfig.front_url}?code=#{params[:code]}&provider=#{params[:provider]}")
      return
    end
    
    if params[:code].blank?
      # flash[:notice] = '取消登录认证'
      # redirect_to(request.referrer)
      render(text: "取消登录认证", status: 401)
      return 
    end
    
    # 开始登录
    # session['wechat.code'] = params[:code]
    if params[:provider] == 'qq'
      user = qq_auth
    elsif params[:provider] == 'wechat'
      user = wechat_auth
    end
    
    if user
      log_in user
      remember(user)
      session['wechat.code'] = nil
      redirect_to params[:url]
    else
      # flash[:error] = '登录认证失败'
      # redirect_back_or(nil)
      render(text: "登录认证失败", status: 401)
    end
    
  end
  
  def app_auth
    redirect_to("#{SiteConfig.front_url}?code=#{params[:code]}&provider=#{params[:provider]}")
  end
  
  private 
  def qq_auth
    original_url = params[:url]

    # 开始获取Token
    resp = RestClient.get "https://graph.qq.com/oauth2.0/token", 
                   { :params => { 
                                  :client_id      => SiteConfig.qq_app_id,
                                  :client_secret  => SiteConfig.qq_app_secret,
                                  :grant_type => "authorization_code",
                                  :code       => params[:code],
                                  :redirect_uri => "#{SiteConfig.auth_redirect_uri}?url=#{original_url}"
                                } 
                   }
                 
    # result = JSON.parse(resp)
    access_token = nil
    
    arr = resp.to_s.split('&')
    arr.each do |item|
      if item.include?('access_token')
        _,access_token = item.split('=') 
        break
      end
    end
    
    if access_token.blank?
      flash[:notice] = '登录认证失败'
      redirect_to(original_url)
      return
    end
    
    puts access_token
    # https://graph.qq.com/oauth2.0/me?access_token=YOUR_ACCESS_TOKEN
    
    resp = RestClient.get "https://graph.qq.com/oauth2.0/me", 
                   { :params => { 
                                  :access_token   => access_token
                                } 
                   }
    
    # result2 = JSON.parse(resp)
    
    result = resp.to_s
    
    _,val = result.split('(')
    val,_ = val.split(')')
    
    result = JSON.parse(val)
    openid = result['openid']
    
    # puts openid
    
    profile = AuthProfile.where(openid: openid, provider: 'qq').first
    if profile.blank?
      # 开始获取用户基本信息
      resp = RestClient.get "https://graph.qq.com/user/get_user_info", 
                     { :params => { 
                                    :access_token   => access_token,
                                    :oauth_consumer_key => SiteConfig.qq_app_id,
                                    :openid => openid
                                  } 
                     }
                     
      user_info_result = JSON.parse(resp)
      
      user = User.create!
      
      profile = AuthProfile.new(openid: openid,
                              nickname: user_info_result['nickname'],
                              sex: user_info_result['gender'],
                              language: user_info_result['language'],
                                  city: user_info_result['city'],
                                  province: user_info_result['province'],
                                  country: user_info_result['country'],
                                  headimgurl: user_info_result['figureurl_qq_2'],
                                  #subscribe_time: result['subscribe_time'],
                                  # unionid: user_info_result['unionid'],
                                  access_token: access_token,
                                  provider: 'qq',
                                  refresh_token: nil)
      profile.user_id = user.uid
      profile.save!
    else
      profile.access_token = access_token
      profile.refresh_token = nil#result['refresh_token']
      profile.save!
      
      user = profile.user
    end
    
    return user
  end
  
  def wechat_auth
    original_url = params[:url]

    # 开始获取Token
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
      flash[:error] = '无效的code，请重试'
      redirect_to(original_url)
      return 
    end
    
    profile = AuthProfile.where(openid: openid, provider: 'wechat').first
    if profile.blank?
      # 开始获取用户基本信息
      user_info = RestClient.get "https://api.weixin.qq.com/sns/userinfo", 
                     { :params => { 
                                    :access_token => result['access_token'],
                                    :openid       => openid,
                                    :lang         => "zh_CN",
                                  } 
                     }
      user_info_result = JSON.parse(user_info)
      
      user = User.create!
      profile = AuthProfile.new(openid: openid,
                                  nickname: user_info_result['nickname'],
                                  sex: user_info_result['sex'],
                                  language: user_info_result['language'],
                                  city: user_info_result['city'],
                                  province: user_info_result['province'],
                                  country: user_info_result['country'],
                                  headimgurl: user_info_result['headimgurl'],
                                  #subscribe_time: result['subscribe_time'],
                                  unionid: user_info_result['unionid'],
                                  access_token: result['access_token'],
                                  provider: 'wechat',
                                  refresh_token: result['refresh_token'])
      profile.user_id = user.uid
      profile.save!
    else
      profile.access_token = result['access_token']
      profile.refresh_token = result['refresh_token']
      profile.save!
      
      user = profile.user
    end
    
    return user
  end
  
  def destroy
    log_out
    render(text: "退出登录成功", status: 200)
    # redirect_back_or(nil)
  end
  
end
