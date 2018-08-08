module API
  module V1
    class FollowsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :follows, desc: '关注相关的接口' do        
        desc "获取粉丝"
        params do
          requires :owner_type, type: String, desc: '粉丝所有者的类型，user或performer'
          requires :owner_id, type: Integer, desc: '粉丝所有者ID'
          optional :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :users do
          unless %w(user performer).include? params[:owner_type]
            return render_error(-1, '不正确的owner_type参数')
          end
          
          ids = Follow.where(followable_type: params[:owner_type].capitalize, followable_id: params[:owner_id]).order('id desc').pluck(:user_id)
          @users = User.where(verified: true, uid: ids)
          if params[:page]
            @users = @users.paginate page: params[:page], per_page: page_size
            total = @users.total_entries
          else
            total = @users.size
          end
          render_json(@users, API::V1::Entities::User, { user: User.find_by(private_token: params[:token]) }, total)
        end # end get users
        
        desc "关注/取消关注"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          requires :follow_type, type: String, desc: '被关注的对象类型，值为User或Performer'
          requires :follow_id,   type: Integer, desc: '被关注的对象ID'
          requires :action, type: String, desc: '关注或取消关注，值为：create或delete'
        end
        post '/:action' do
          user = authenticate!
          
          unless %w(create delete).include? params[:action]
            return render_error(-1, '不正确的action参数')
          end
          
          unless %w(User Performer).include? params[:follow_type]
            return render_error(-1, '不正确的follow_type参数')
          end
          
          count = Follow.where(user_id: user.uid, followable_type: params[:follow_type], followable_id: params[:follow_id]).count
          if params[:action] == 'create'
            if count > 0
              return render_error(5001, '你已经关注了')
            end
          else
            if count == 0
              return render_error(5001, '还未关注，不能取消')
            end
          end
          
          if params[:action] == 'create'
            follow = Follow.create!(user_id: user.uid, followable_type: params[:follow_type], followable_id: params[:follow_id])
            follow.change_stats!(1)
          else
            follow = Follow.where(user_id: user.uid, followable_type: params[:follow_type], followable_id: params[:follow_id]).first
            follow.change_stats!(-1)
            Follow.where(user_id: user.uid, followable_type: params[:follow_type], followable_id: params[:follow_id]).delete_all
          end
          
          render_json_no_data
        end # end post action
        
      end # end resource
      
    end
  end
end