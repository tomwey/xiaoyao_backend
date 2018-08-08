module API
  module V1
    class ReportsAPI < Grape::API
      helpers API::SharedParams
      
      resource :reports, desc: '举报接口' do
        desc "创建举报"
        params do
          requires :event_id, type: Integer, desc: '活动ID'
          requires :token,    type: String, desc: '用户TOKEN'
          requires :content,  type: String, desc: '举报内容'
          optional :loc,      type: String, desc: '经纬度，用英文逗号分隔，例如：104.20303,30.02022'
        end
        post do
          user = authenticate!
          
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          Report.create!(content: params[:content], user_id: user.id, event_id: event.id, ip: client_ip, location: loc)
          
          render_json_no_data
          
        end # end post
      end # end resource
    end
  end
end