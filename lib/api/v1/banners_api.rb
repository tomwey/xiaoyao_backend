# require 'rest-client'
module API
  module V1
    class BannersAPI < Grape::API
      resource :banners, desc: 'Banner广告相关接口' do
        desc '获取一定数量Banner'
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取的数量'
        end
        get do
          @banners = Banner.opened.sorted.order('id desc').limit(5)
          render_json(@banners, API::V1::Entities::Banner)
        end # end get 
        
      end
    end
  end
end