module API
  module V1
    class MessagesAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :messages, desc: "消息相关接口" do 
        desc "获取未读消息条数"
        params do
          requires :token, type: String, desc: "用户Token"
        end 
        get :unread_count do
          user = authenticate!
          
          # if user.read_sys_msg_at.blank?
          #   where('(messages.to = ? and read_at is null) or (messages.to is null)', user.id)
          # else
          #   where('(messages.to = ? and read_at is null) or (messages.to is null and created_at > ?)', user.id, user.read_sys_msg_at)
          # end
          
          # 获取未读的系统公告
          if user.read_sys_msg_at.blank?
            sys_count = Message.where('messages.to is null').count
          else
            sys_count = Message.where('messages.to is null and created_at > ?', user.read_sys_msg_at).count
          end
          
          # 获取未读的消息
          msg_count = Message.where('messages.to = ? and read_at is null', user.id).count
          # count = Message.unread_for(user).count
          
          { count: (sys_count + msg_count), sys_msg_count: sys_count, msg_count: msg_count }
        end # end get unread_count
        
        desc "获取系统公告，并修改状态为已读"
        params do
          requires :token, type: String, desc: "用户Token"
          use :pagination
        end
        get :notify do
          user = authenticate!
          
          # 只在第一次加载的时候标记未读消息为已读
          if params[:page].blank? or params[:page].to_i <= 1
            user.update_attribute(:read_sys_msg_at, Time.zone.now)
          end
          
          @messages = Message.where('messages.to is null').order('id desc')
          if params[:page]
            @messages = @messages.paginate page: params[:page], per_page: page_size
          end
          
          render_json(@messages, API::V1::Entities::Message)
          
        end # end get notify
        
        desc "获取消息列表，并修改消息的状态为已读"
        params do
          requires :token, type: String, desc: "用户Token"
          use :pagination
        end
        get :list do
          user = authenticate!
          
          # 只在第一次加载的时候标记未读消息为已读
          if params[:page].blank? or params[:page].to_i <= 1
            # user.update_attribute(:read_sys_msg_at, Time.zone.now)
            Message.where('messages.to = ? and read_at is null', user.id).update_all(read_at: Time.zone.now)
          end
          
          @messages = Message.where('messages.to = ?', user.id).order('id desc')
          if params[:page]
            @messages = @messages.paginate page: params[:page], per_page: page_size
          end
          
          render_json(@messages, API::V1::Entities::Message)
          
        end # end get list
      end # end resource
      
    end
  end
end