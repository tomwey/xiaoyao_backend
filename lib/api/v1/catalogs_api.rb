# require 'rest-client'
module API
  module V1
    class CatalogsAPI < Grape::API
      
      resource :catalogs, desc: '分类相关接口' do
        desc '获取分类'
        get do
          @catalogs = Catalog.where(opened: true).order('sort asc, id desc')
          render_json(@catalogs, API::V1::Entities::Catalog)
        end # end get /
      end # end resource
      
      resource :themes, desc: '红包模板相关接口' do
        desc '获取某个分类下面的所有模板'
        params do
          requires :cid, type: Integer, desc: '分类ID'
          optional :token, type: String, desc: '用户认证TOKEN'
        end
        get do
          
          if params[:cid] == 0 # 获取自定义模板
            user = User.find_by(private_token: params[:token])
            if user.blank?
              render_error(4000, '获取自定义模板失败')
              return
            else
              @themes = RedpackTheme.where(opened: true, user_id: user.uid)
                          .order('sort asc, id desc')
              render_json(@themes, API::V1::Entities::RedpackTheme)
            end
          end
          
          # 获取通用数据
          @catalog = Catalog.find_by(uniq_id: params[:cid])
          if @catalog.blank?
            return render_error(4004, '分类不存在')
          end
          
          @themes = RedpackTheme.where(opened: true)
            .where("'#{@catalog.uniq_id}' = ANY (tags)")
            .order('sort asc, id desc')
            
          render_json(@themes, API::V1::Entities::RedpackTheme)
          
        end # end /
      end # end resource
        
      resource :audios, desc: '红包音效相关接口' do
        desc '获取某个分类下面的所有音效'
        params do
          requires :cid, type: Integer, desc: '分类ID'
          optional :token, type: String, desc: '用户认证TOKEN'
        end
        get do
          @catalog = Catalog.find_by(uniq_id: params[:cid])
          if @catalog.blank?
            return render_error(4004, '分类不存在')
          end
        
          @audios = RedpackAudio.where(opened: true)
            .where("'#{@catalog.uniq_id}' = ANY (tags)")
            .order('sort asc, id desc')
          
          render_json(@audios, API::V1::Entities::RedpackAudio)
        
        end # end /
      end #end resource

    end # end class
  end
end