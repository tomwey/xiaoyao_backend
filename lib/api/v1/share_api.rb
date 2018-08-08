# require 'rest-client'
module API
  module V1
    class ShareAPI < Grape::API
      resource :share, desc: '活动分享统计' do
        desc "活动分享统计"
        params do
          requires :token, type: String, desc: 'TOKEN'
          requires :event_id, type: Integer, desc: '活动ID'
        end
        post :event do
          user = authenticate!
          
          @event = Event.find_by(uniq_id: params[:event_id])
          if @event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          EventShareLog.create!(user_id: user.id, event_id: @event.id, ip: client_ip)
          
          render_json_no_data
        end # end post event
        
        desc "活动分享统计2"
        params do
          requires :token, type: String, desc: 'TOKEN'
          requires :redbag_id, type: Integer, desc: '活动ID'
        end
        post :redbag do
          user = authenticate!
          
          @redbag = Redbag.find_by(uniq_id: params[:redbag_id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          RedbagShareLog.create!(user_id: user.id, redbag_id: @redbag.id, ip: client_ip)
          
          render_json_no_data
        end # end post event
        
        desc "获取分享的配置信息"
        params do
          requires :url, type: String, desc: '需要签名的url'
          optional :token, type: String, desc: 'TOKEN'
          optional :event_id, type: Integer, desc: '活动ID，可能为null，如果为空，那么表示是官方内容分享'
        end
        get :config do 
          # type = (params[:type] || 1).to_i
          
          user = User.find_by(private_token: params[:token])
          
          url = (params[:url].start_with?('http://') or params[:url].start_with?('https://')) ? params[:url] : SiteConfig.send(params[:url])
          json = Wechat::Sign.sign_package(url)
          
          @event = Event.find_by(uniq_id: params[:event_id])
          
          if @event.blank?
            # 官方分享
            content = { 
              title: CommonConfig.share_title || '',
              desc: CommonConfig.share_desc || '',
              link: "http://#{SiteConfig.app_domain}/wx/share?token=#{user.private_token}",
              img_url: CommonConfig.share_image_url || '',
            } 
          else
            # 活动分享
            title = "我刚刚在小优大惠领了#{user.balance}元，爽翻..."
            content = { 
              title: title,
              desc: CommonConfig.share_desc || '',
              link: "http://#{SiteConfig.app_domain}/wx/events/#{@event.uniq_id}/share?token=#{user.private_token}",
              img_url: CommonConfig.share_image_url || '',
            }
          end
          
          { code: 0, message: 'ok', data: { config: json, content: content } }
          
        end # end get config
        
      end # end resource 
    end
  end
end