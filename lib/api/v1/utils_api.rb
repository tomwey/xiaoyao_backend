require 'rest-client'
module API
  module V1
    class UtilsAPI < Grape::API
      resource :util, desc: '工具接口' do
        desc "获取微信JSSDK配置数据"
        params do
          requires :url, type: String, desc: '需要签名的url'
        end
        get :wx_config do
          url = (params[:url].start_with?('http://') or params[:url].start_with?('https://')) ? params[:url] : SiteConfig.send(params[:url])
          json = Wechat::Sign.sign_package(url)
          { code: 0, message: 'ok', data: json }
        end # end get
        
        desc "获取微信授权登录地址"
        params do
          optional :url, type: String, desc: '需要授权登录的H5页面地址'
        end
        get :wx_auth do
          redirect_url  = "http://b.hb.small-best.com/wx/auth/redirect2"
          @wx_auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&response_type=code&scope=snsapi_userinfo&state=yujian#wechat_redirect"
          { code: 0, message: 'ok', data: { url: @wx_auth_url } }
        end # end get wx_auth
        
        desc "处理微信授权登录"
        params do
          requires :code, type: String, desc: '微信返回的授权登录code'
        end
        post :wx_bind do
          # 开始获取用户信息
          resp = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token", 
                         { :params => { 
                                        :appid      => SiteConfig.wx_app_id,
                                        :secret     => SiteConfig.wx_app_secret,
                                        :grant_type => "authorization_code",
                                        :code       => params[:code]
                                      } 
                         }
                 
          result = JSON.parse(resp)
          # puts result
          openid = result['openid'];
          if openid.blank?
            # puts '-10'
            return render_error(-10, '无效的openid')
          end
    
          profile = WechatProfile.find_by(openid: openid)
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
            
            user = User.new
            profile = WechatProfile.new(openid: openid,
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
                                        refresh_token: result['refresh_token'])
            user.wechat_profile = profile
            user.save!
          else
            profile.access_token = result['access_token']
            profile.refresh_token = result['refresh_token']
            profile.save!
      
            user = profile.user
          end
          
          if user.blank?
            # puts '4004'
            return render_error(4004, '获取用户信息失败')
          end
          { code: 0, message: 'ok', data: { token: user.private_token } }
        end # end wx_bind
        
      end
    end
  end
end