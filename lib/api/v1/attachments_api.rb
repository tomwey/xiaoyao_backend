module API
  module V1
    class AttachmentsAPI < Grape::API
      
      resource :assets, desc: '附件相关接口' do
        desc "上传附件"
        params do
          requires :token,          type: String, desc: 'TOKEN'
          requires :file,           type: Rack::Multipart::UploadedFile
          optional :assetable_type, type: String, desc: '关联的附件类别名'
          optional :assetable_id,   type: Integer, desc: '关联的附件类别ID'
        end
        post do
          user = authenticate!
          asset = Attachment.create!(data: params[:file], ownerable: user)
          render_json(asset, API::V1::Entities::Attachment)
        end # end post upload
        
        desc "上传多个附件"
        params do
          requires :token,          type: String, desc: 'TOKEN'
          requires :files,          type: Array do
            requires :file, type: Rack::Multipart::UploadedFile, desc: '二进制文件'
          end
          optional :assetable_type, type: String, desc: '关联的附件类别名'
          optional :assetable_id,   type: Integer, desc: '关联的附件类别ID'
        end
        post :upload2 do
          user = authenticate!
          
          assets = []
          params[:files].each do |param|
            asset = Attachment.create!(data: param[:file], ownerable: user)
            assets << asset
          end
          render_json(assets, API::V1::Entities::Attachment)
        end # end post upload
        
        desc "查询附件"
        params do
          requires :token, type: String, desc: 'TOKEN'
        end
        get '/:id' do
          user = authenticate!
          asset = Attachment.find_by(uniq_id: params[:id])
          if asset.blank?
            return render_error(4004, '附件不存在')
          end
          render_json(asset, API::V1::Entities::Attachment)
        end # end get
        
      end # end resource
      
    end
  end
end