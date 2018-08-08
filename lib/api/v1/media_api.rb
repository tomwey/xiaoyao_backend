require 'rest-client'
module API
  module V1
    class MediaAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :media, desc: '多媒体相关接口' do
        
        desc "获取播放历史"
        params do
          requires :token,  type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :histories do
          user = authenticate!
          
          @logs = MediaPlayLog.select('DISTINCT ON (media_id) *').where(user_id: user.uid).order('media_id asc, created_at desc')
          render_json(@logs, API::V1::Entities::MediaPlayLog)
        end # end get histories
        
        desc "获取某个艺人的MV列表"
        params do
          requires :id, type: Integer, desc: '艺人的ID'
          optional :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :my_list do
          @medias = Media.opened.where(owner_id: params[:id]).order('id desc')
          if params[:page]
            @medias = @medias.paginate page: params[:page], per_page: page_size
            total = @medias.total_entries
          else
            total = @medias.size
          end
          
          render_json(@medias, API::V1::Entities::MediaDetail, { user: User.find_by(private_token: params[:token]) }, total)
        end #end get owning
        
        desc "获取MV列表"
        params do
          requires :action, type: String, desc: '值为latest或hot'
          optional :school, type: String, desc: '学校'
          optional :token,  type: String, desc: '用户TOKEN'
          use :pagination
        end
        get '/:action' do
          unless %w(latest hot).include? params[:action]
            return render_error(-1, '不正确的action参数，值为latest或hot')
          end
          
          @medias = Media.opened.send(params[:action])
          if params[:school] && params[:school] != '全部'
            @medias = @medias.joins("inner join performers on performers.uniq_id = media.owner_id")
            .where('performers.school = ?', params[:school])
          end
          
          if params[:page]
            @medias = @medias.paginate page: params[:page], per_page: page_size
            total = @medias.total_entries
          else
            total = @medias.size
          end
          
          render_json(@medias, API::V1::Entities::MediaDetail, { user: User.find_by(private_token: params[:token]) }, total)
          
        end # end get list
        
        desc "播放统计"
        params do
          requires :id, type: Integer, desc: '媒体资源ID'
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc, type: String, desc: '用户观看的位置，格式为lng,lat，例如：104.03303,30.3030393'
        end
        post :play do
          @media = Media.find_by(uniq_id: params[:id])
          if @media.blank?
            return render_error(4004, '作品不存在')
          end
          
          user = User.find_by(private_token: params[:token])
          
          loc = nil
          if params[:loc]
            loc = "POINT(#{params[:loc].gsub(',', ' ')})"
          end
          MediaPlayLog.create!(user_id: user.try(:uid), media_id: @media.uniq_id, ip: client_ip, location: loc)
          
          render_json_no_data
        end # end post play
        
      end # end resource
      
    end
  end
end