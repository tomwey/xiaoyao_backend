module API
  module V1
    class LikesAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :likes, desc: '喜欢相关的接口' do
        
        desc "获取我喜欢的"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          optional :like_type, type: String,  desc: '喜欢的对象类型，默认为Media'
          use :pagination
        end
        get do
          user = authenticate!
          
          type = params[:like_type] || 'Media'
          
          @likes = Like.where(user_id: user.uid, likeable_type: type).order('id desc')
          if params[:page]
            @likes = @likes.paginate page: params[:page], per_page: page_size
            total = @likes.total_entries
          else
            total = @likes.size
          end
          
          render_json(@likes, API::V1::Entities::Like, {}, total)
          
        end # end get /
        
        desc "添加喜欢"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          optional :like_type, type: String,  desc: '喜欢的对象类型，默认为Media'
          requires :like_id,   type: Integer, desc: '喜欢的对象ID'
        end
        post :create do
          user = authenticate!
          
          type = params[:like_type] || 'Media'
          klass = Object.const_get type
          @likeable = klass.find_by(uniq_id: params[:like_id])
          if @likeable.blank?
            return render_error(4004, '对象不存在')
          end
          
          if user.liked?(@likeable)
            return render_error(1001, '已经喜欢过了')
          end
          
          like = Like.create!(user_id: user.uid, likeable_type: @likeable.class, likeable_id: @likeable.uniq_id || @likeable.id)
          
          # render_json_no_data
          
          render_json(like, API::V1::Entities::Like)
          
        end # end like create
        
        desc "取消喜欢"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          optional :like_type, type: String,  desc: '喜欢的对象类型，默认为Media'
          requires :like_id,   type: Integer, desc: '喜欢的对象ID'
        end
        post :delete do
          user = authenticate!
          
          type = params[:like_type] || 'Media'
          klass = Object.const_get type
          @likeable = klass.find_by(uniq_id: params[:like_id])
          if @likeable.blank?
            return render_error(4004, '对象不存在')
          end
          
          unless user.liked?(@likeable)
            return render_error(1001, '您还未喜欢，不能取消')
          end
          
          Like.where(user_id: user.uid, likeable_type: @likeable.class, likeable_id: @likeable.uniq_id || @likeable.id).delete_all
          
          @likeable.change_likes_count!(-1)
          
          render_json_no_data
          
        end # end like delete
        
      end # end resource
      
    end
  end
end