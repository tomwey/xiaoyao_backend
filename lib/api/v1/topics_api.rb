module API
  module V1
    class TopicsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :topics, desc: '动态相关的接口' do
        
        desc "发动态"
        params do
          requires :token,     type: String,  desc: '用户TOKEN'
          requires :content,   type: String, desc: '评论内容'
          optional :file_type, type: Integer,  desc: '附件类型，1 表示图片，2 表示音频 2表示视频'
          optional :files,     type: Array do
            requires :file, type: Rack::Multipart::UploadedFile, desc: '二进制文件'
          end
          optional :address, type: String, desc: '评论的地理位置'
        end
        post :create do
          user = authenticate!
          
          type = nil
          if params[:file_type]
            unless %w(1 2 3).include? params[:file_type].to_s
              return render_error(-1, '不正确的file_type参数')
            end
            type = params[:file_type]
          end
          
          topic = Topic.create!(content: params[:content], 
                                attachment_type: type, 
                                ip: client_ip, 
                                address: params[:address],
                                ownerable_type: user.class,
                                ownerable_id: user.uid
                                )
          
          files = params[:files] || []   
          files.each do |param|
            Attachment.create!(data: param[:file], 
                               ownerable_type: user.class, 
                               ownerable_id: user.uid,
                               ip: client_ip,
                               address: params[:address],
                               attachable_type: topic.class,
                               attachable_id: topic.uniq_id
                               )
          end
          
          render_json_no_data
        end # end like create
        
        desc "获取动态"
        params do
          optional :token,  type: String,  desc: '用户TOKEN'
          requires :action, type: String, desc: '动态分类，值为：suggest,latest,following,liked,my_list之一'
          use :pagination
        end
        get '/:action' do
          
          unless %w(suggest latest following liked my_list).include? params[:action]
            return render_error(-1, '不正确的action参数')
          end
          
          user = User.find_by(private_token: params[:token])
          
          if params[:action] == 'following' or params[:action] == 'liked' or params[:action] == 'my_list'
            if user.blank?
              return render_error(4001, '您还未登录')
            end
            if params[:action] == 'following'
              @topics = Topic.where('topics.opened = ?', true).following_for(user).order('topics.id desc')
            elsif params[:action] == 'liked'
              @topics = Topic.where('topics.opened = ?', true).liked_for(user).order('topics.id desc')
            else
              @topics = Topic.where(opened: true).where(ownerable_type: 'User', ownerable_id: user.uid).order('id desc')
            end
            
          else
            @topics = Topic.where(opened: true).send(params[:action].to_sym)
          end
          
          if params[:page]
            @topics = @topics.paginate page: params[:page], per_page: page_size
            total = @topics.total_entries
          else
            total = @topics.size
          end
          
          render_json(@topics, API::V1::Entities::Topic, {user: user}, total)
          
        end # end get /
        
      end # end resource
      
    end
  end
end