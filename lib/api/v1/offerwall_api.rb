module API
  module V1
    class OfferwallAPI < Grape::API
      resource :offerwall, desc: '积分墙相关接口' do
        
        desc '获取渠道信息列表'
        params do
          requires :token, type: String, desc: '用户认证TOKEN'
          optional :os,    type: String, desc: '系统平台'
        end
        get :channels do
          user = authenticate!
          
          os = if request.from_ios?
            'iOS'
          elsif request.from_android?
            'Android'
          else
            ''
          end
          
          os = params[:os] || os
          
          if os.blank?
            return render_error(-1, '不支持的平台')
          end
          
          @channels = OfferwallChannel.opened.where(platform: os).sorted
          
          render_json(@channels, API::V1::Entities::OfferwallChannel, { user: user })
        end
        
      end # end resource
    end
  end
end