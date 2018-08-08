module API
  module V1
    class UsersAPI < Grape::API
      
      helpers API::SharedParams
      
      # 获取用户账号登录地址
      resource :u, desc: '网页授权登录接口' do
        desc "获取登录地址"
        params do
          optional :url, type: String, desc: '需要授权登录的H5页面地址'
        end
        get :auth do
          
          # redirect_url  = "http://hhd.afterwind.cn/auth/redirect"
          
          ua = request.user_agent
          is_wx_browser = ua.include?('MicroMessenger') || ua.include?('webbrowser')
          
          if is_wx_browser
            # puts '是微信浏览器'
            # url = request.original_url
            
            redirect_url = "#{SiteConfig.h5_auth_redirect_uri}?provider=wechat&from_url=#{params[:url]}"
            # redirect_url  = "#{SiteConfig.auth_redirect_uri}?url=#{url}&provider=wechat"#"#{wechat_auth_redirect_url}?url=#{request.original_url}"

            auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{SiteConfig.wx_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&response_type=code&scope=snsapi_userinfo&state=redpack#wechat_redirect"
            # redirect_to @wx_auth_url
          else
            
            redirect_url = "#{SiteConfig.h5_auth_redirect_uri}?provider=qq&from_url=#{params[:url]}"
            
            auth_url = "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=#{SiteConfig.qq_app_id}&redirect_uri=#{Rack::Utils.escape(redirect_url)}&scope=get_user_info"
          end
          
          { code: 0, message: 'ok', data: { url: auth_url } }
          
        end # end get auth
        
        desc "绑定三方账号"
        params do
          requires :code, type: String, desc: '三方登录返回的code'
          requires :provider, type: String, desc: '三方平台名称'
          optional :rid, type: String, desc: '红包ID'
        end
        post :auth_bind do
          u = UserAuth.create_user(params[:provider], params[:code], "#{SiteConfig.h5_auth_redirect_uri}?provider=qq")
          if u.blank?
            return render_error(4003, '认证登录失败')
          end
          
          { code: 0, message: 'ok', data: { token: u.private_token } }
        end # end auth_bind
        
      end # end resource u
      
      # 用户账号管理
      resource :account, desc: "注册登录接口" do
        desc "APP用户简单注册"
        params do
          requires :uuid,  type: String, desc: '用户设备唯一ID'
          requires :model, type: String, desc: '设备名称'
          requires :os,    type: String, desc: '操作系统'
          requires :osv,   type: String, desc: '系统版本'
          optional :uname, type: String, desc: '设备用户名字'
          optional :screen, type: String, desc: '设备分辨率'
          optional :lang_code, type: String, desc: '国家语言，例如：zh_CN'
        end
        post :create do
          uuid = params[:uuid]          
          device = UserDevice.find_by(uuid: uuid)
          if device.blank?
            device = UserDevice.new(uuid: uuid, 
                                    model: params[:model], 
                                    os: params[:os], 
                                    os_version: params[:osv],
                                    uname: params[:uname],
                                    screen_size: params[:screen],
                                    lang_code: params[:lang_code]
                                    )
            user = User.create!
            device.uid = user.uid
            
            if device.save
              render_json(user, API::V1::Entities::UserBase)
            else
              render_error(4002, '注册失败!')
            end
          else
            render_json(device.user, API::V1::Entities::UserBase)
          end
          
        end # end create
        
      end # end account resource
      
      resource :user, desc: "用户接口" do
        
        desc "获取个人资料"
        params do
          requires :token, type: String, desc: "用户认证Token"
        end
        get :me do
          user = authenticate!
          render_json(user, API::V1::Entities::User)
        end # end get me
        
        desc "交易明细"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :trades do
          user = authenticate!
          @logs = TradeLog.where(user_id: user.uid).order('created_at desc')
          if params[:page]
            @logs = @logs.paginate page: params[:page], per_page: page_size
            total = @logs.total_entries
          else
            total = @logs.size
          end
          render_json(@logs, API::V1::Entities::TradeLog, {}, total)
        end # end get trades
        
        desc "用户会话开始"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          optional :type,      type: Integer, desc: '值为1或2或3；1表示APP Launch, 2表示 APP Resume'
          optional :loc,       type: String,  desc: '用户当前位置，值格式为：lng,lat'
          optional :network,   type: String,  desc: '用户当前的网络类型，例如：wifi, 3g, 4g'
          optional :version,   type: String,  desc: '当前客户端的版本号'
          optional :uuid,      type: String,  desc: '设备UUID'
          optional :os,        type: String,  desc: '设备系统'
          optional :osv,       type: String,  desc: '设备系统版本号'
          optional :model,     type: String,  desc: '设备型号，例如：iPhone 5s'
          optional :screen,    type: String, desc: '设备分辨率'
          optional :uname,     type: String, desc: '设备用户名字'
          optional :lang_code, type: String,  desc: '国家语言码，例如：zh_CN'
        end
        post '/session/begin' do
          user = authenticate!
          
          if params[:loc]
            loc = "POINT(#{params[:loc].gsub(',', ' ')})"
          else
            loc = nil
          end
          
          us = UserSession.create!(uid: user.uid, 
                              begin_time: Time.zone.now,
                              take_type: (params[:type] || 2).to_i,
                              location: loc,
                              app_version: params[:version],
                              ip: client_ip, 
                              network: params[:network],
                              uuid: params[:uuid],
                              os: params[:os],
                              os_version: params[:osv],
                              model: params[:model],
                              screen_size: params[:screen],
                              uname: params[:uname],
                              lang_code: params[:lang_code])
            
          @app_version = AppVersion.where('version > ? and lower(os) = ?', 
                                          params[:version], params[:os].downcase)
                                          .where(opened: true).order('version desc').first
          
          result = {
            session_id: us.uniq_id,
            config: {
              explore_url: SiteConfig.app_explore_url,
              kefu_url: SiteConfig.kefu_url,
              aboutus_url: SiteConfig.aboutus_url,
              faq_url: SiteConfig.faq_url,
              ad_blacklist: SiteConfig.ad_blacklist.split(',')
            }
          }
          
          if @app_version
            result = {
              session_id: us.uniq_id,
              config: {
                explore_url: SiteConfig.app_explore_url,
                kefu_url: SiteConfig.kefu_url,
                aboutus_url: SiteConfig.aboutus_url,
                faq_url: SiteConfig.faq_url,
                ad_blacklist: SiteConfig.ad_blacklist.split(','),
                ad_script: "var $el = $('a[id^=__a_z_]'); $el.hide();"
              },
              new_version: API::V1::Entities::AppVersion.represent(@app_version)
            }
          else
            result = {
              session_id: us.uniq_id,
              config: {
                explore_url: SiteConfig.app_explore_url,
                kefu_url: SiteConfig.kefu_url,
                aboutus_url: SiteConfig.aboutus_url,
                faq_url: SiteConfig.faq_url,
                ad_blacklist: SiteConfig.ad_blacklist.split(','),
                ad_script: "var $el = $('a[id^=__a_z_]'); $el.hide();"
              }
            }
          end
          
          { code: 0, message: 'ok', data: result }
        end # end post session begin
        
        desc "用户会话结束"
        params do
          requires :token,     type: String, desc: '用户TOKEN'
          requires :session_id,type: String, desc: '会话ID'
        end
        post '/session/end' do
          user = authenticate!
          
          us = UserSession.where(uid: user.uid, uniq_id: params[:session_id]).first
          us.end_time = Time.zone.now
          us.save!
          
          render_json_no_data
        end
        
        desc "获取VIP充值列表"
        params do
          requires :token, type: String, desc: '用户TOKEN'
        end
        get :vip_charge_list do
          user = authenticate!
          
          @vipcards = VipCard.where(actived_user_id: user.uid).where.not(actived_at: nil).order('actived_at desc')
          
          render_json(@vipcards, API::V1::Entities::VipCard)
        end # end get vip_charge_list
        
        desc "VIP激活"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          requires :code,  type: String, desc: 'VIP卡号'
        end
        post '/vip/active' do
          user = authenticate!
          
          card = VipCard.find_by(code: params[:code])
          if card.blank?
            return render_error(4004, 'VIP卡不存在')
          end
          
          if not card.in_use
            return render_error(-1, 'VIP卡不可用')
          end
          
          if card.actived_at.present?
            return render_error(-1, 'VIP卡已经被激活')
          end
          
          user.active_vip_card!(card)
          
          render_json_no_data
          
        end # end vip active
        
        desc "获取我正在关注的对象"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :followings do
          user = authenticate!
          
          @follows = Follow.where(user_id: user.uid).order('id desc')
          if params[:page]
            @follows = @follows.paginate page: params[:page], per_page: page_size
            total = @follows.total_entries
          else
            total = @follows.size
          end
          
          render_json(@follows, API::V1::Entities::Follow, {}, total)
        end # end get followings
        
      end # end user resource
      
    end 
  end
end