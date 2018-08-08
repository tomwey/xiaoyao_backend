module API
  module V1
    class CommentsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :comments, desc: '评论相关的接口' do
        
        desc "获取评论"
        params do
          optional :token,     type: String,  desc: '用户TOKEN'
          requires :comment_type, type: String,  desc: '被评论的类型，默认为Media'
          requires :comment_id, type: Integer,  desc: '被评论的对象ID'
          use :pagination
        end
        get do
          @comments = Comment.where(opened: true).where(commentable_type: params[:comment_type], commentable_id: params[:comment_id]).order('created_at desc')
          if params[:page]
            @comments = @comments.paginate page: params[:page], per_page: page_size
            total = @comments.total_entries
          else
            total = @comments.size
          end
          
          render_json(@comments, API::V1::Entities::Comment, {}, total)
          
        end # end get /
        
        desc "发评论"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          requires :comment_type, type: String,  desc: '评论的对象类型，默认为Media'
          requires :comment_id,   type: Integer, desc: '评论的对象ID'
          requires :content, type: String, desc: '评论内容'
          optional :address, type: String, desc: '评论的地理位置'
        end
        post :create do
          user = authenticate!
          
          klass = Object.const_get params[:comment_type]
          @commentable = klass.find_by(uniq_id: params[:comment_id])
          if @commentable.blank?
            return render_error(4004, '被评论的对象不存在')
          end
          
          @comment = Comment.create!(user_id: user.uid, commentable_type: @commentable.class, commentable_id: @commentable.uniq_id || @commentable.id, content: params[:content], ip: client_ip, address: params[:address])
          
          render_json(@comment, API::V1::Entities::Comment)
          
        end # end like create
        
        desc "获取某条评论下的回复"
        params do
          optional :token,     type: String,  desc: '用户TOKEN'
          requires :comment_id, type: String,  desc: '评论的对象类型，默认为Media'
        end
        get '/:comment_id/replies' do
          @comment = Comment.find_by(id: params[:comment_id])
          if @comment.blank?
            return render_error(4004, '评论不存在')
          end
          
          @replies = Reply.where(comment_id: @comment.id, opened: true).order('created_at asc')
          render_json(@replies, API::V1::Entities::Reply)
        end # end get replies
        
        desc "回复评论"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          requires :comment_id, type: String,  desc: '评论的对象类型，默认为Media'
          requires :content, type: String, desc: '回复内容'
          optional :to_user, type: Integer, desc: '回复给某个用户, 用户ID'
          optional :address, type: String, desc: '地理位置'
        end
        post '/:comment_id/create_reply' do
          from_user = authenticate!
          @comment = Comment.find_by(id: params[:comment_id])
          if @comment.blank?
            return render_error(4004, '评论不存在')
          end
          
          @reply = Reply.create!(from_user_id: from_user.uid, 
                                 to_user_id: User.find_by(uid: params[:to_user]).try(:uid),
                                 comment_id: @comment.id,
                                 content: params[:content],
                                 ip: client_ip,
                                 address: params[:address]
                                 )
                                 
          render_json(@reply, API::V1::Entities::Reply)
        end # end post create_reply
        
      end # end resource
      
    end
  end
end