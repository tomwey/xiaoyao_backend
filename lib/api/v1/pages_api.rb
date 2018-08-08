module API
  module V1
    class PagesAPI < Grape::API
      resource :p, desc: '网页相关接口' do
        desc "获取某个网页的数据"
        params do
          requires :slug, type: String, desc: '网页文档标识'
        end
        get '/:slug' do
          @page = Page.find_by(slug: params[:slug])
          if @page.blank?
            return render_error(4004, '网页文档不存在')
          end
          
          render_json(@page, API::V1::Entities::Page)
        end # end get slug
        
      end # end resource
    end
  end
end