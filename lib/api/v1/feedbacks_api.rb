module API
  module V1
    class FeedbacksAPI < Grape::API
      
      resource :feedbacks, desc: '意见反馈接口' do
        desc "意见反馈"
        params do
          requires :token,   type: String, desc: '用户Token'
          requires :content, type: String, desc: "反馈内容，必须"
          optional :author,  type: String, desc: "用户联系方式"
          optional :files,          type: Array do
            requires :file, type: Rack::Multipart::UploadedFile, desc: '二进制文件'
          end
        end
        post do
          user = authenticate!
          
          @feedback = Feedback.new(author: params[:author] || user.format_nickname, content: params[:content])
          @feedback.user_id = user.id
          assets = []
          params[:files].each do |param|
            asset = Attachment.new(data: param[:file], ownerable: user)
            assets << asset
          end
          
          @feedback.attachments = assets
          
          if @feedback.save
            render_json_no_data
          else
            render_error(5001, @feedback.errors.full_messages.join(','))
          end
        end
      end # end resource
      
    end
  end
end