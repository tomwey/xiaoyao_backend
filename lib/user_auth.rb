require 'rest-client'

class UserAuth
  def self.create_user(provider, code, redirect_uri)
    if provider == 'qq'
      return UserAuth.qq_auth(code, redirect_uri)
    elsif provider == 'wechat'
      return UserAuth.wechat_auth(code, redirect_uri)
    else
      nil
    end
  end
  
  def self.qq_auth(code, redirect_uri)
    # original_url = params[:url]

    # 开始获取Token
    resp = RestClient.get "https://graph.qq.com/oauth2.0/token", 
                   { :params => { 
                                  :client_id      => SiteConfig.qq_app_id,
                                  :client_secret  => SiteConfig.qq_app_secret,
                                  :grant_type => "authorization_code",
                                  :code       => code,
                                  :redirect_uri => redirect_uri
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
      return nil
    end
    
    # puts access_token
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
  
  def self.wechat_auth(code, redirect_uri)
    # 开始获取Token
    resp = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token", 
                   { :params => { 
                                  :appid      => SiteConfig.wx_app_id,
                                  :secret     => SiteConfig.wx_app_secret,
                                  :grant_type => "authorization_code",
                                  :code       => code
                                } 
                   }
                 
    result = JSON.parse(resp)
    
    openid = result['openid'];
    if openid.blank?
      return nil
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
  
end