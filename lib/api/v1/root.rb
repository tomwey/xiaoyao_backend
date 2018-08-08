module API
  module V1
    class Root < Grape::API
      version 'v1'
      
      helpers API::CommHelpers
      helpers API::SharedParams
      
      # 接口访问权限认证
      before do        
        is_pro = Rails.env.production?
        # 如果访问的是API文档，那么不做判断
        is_api_doc_path = request.path.include? "swagger_doc"
        encode_str = Base64.urlsafe_encode64(SiteConfig.api_key + params[:i].to_s)
        # (Time.now.to_i - params[:i].to_i) > SiteConfig.access_key_expire_in.to_i
        from_api_doc = request.referer && request.referer.include?('/apidoc')
        # allow_access = request.path.include? "data/mobile"
        white_lists = []
        if SiteConfig.api_white_lists
          white_lists = SiteConfig.api_white_lists.split(',')
        end
        if !white_lists.include?(request.path) && !from_api_doc && is_pro && !is_api_doc_path
          encode_str = Digest::MD5.hexdigest(SiteConfig.api_key + params[:i].to_s)
          if ( (params[:ak].blank? or params[:i].blank?) or encode_str != params[:ak] or $redis.get('ak_code') == params[:i].to_s )
            error!({"code" => 403, "message" => "没有访问权限"}, 403)
          else
            # session[:ak_code] = params[:i].to_s
            # 保存上次访问的code
            $redis.set('ak_code', params[:i].to_s)
          end
        end
      end
      
      mount API::V1::HomeAPI
      mount API::V1::MediaAPI
      mount API::V1::UsersAPI
      # mount API::V1::RedpackAPI
      mount API::V1::PagesAPI
      # mount API::V1::CatalogsAPI
      mount API::V1::PayAPI
      mount API::V1::UtilsAPI
      mount API::V1::LikesAPI
      mount API::V1::CommentsAPI
      mount API::V1::TopicsAPI
      mount API::V1::VotesAPI
      mount API::V1::FollowsAPI
      # mount API::V1::UsersAPI
      # mount API::V1::BannersAPI
      # mount API::V1::MediaAPI
      # mount API::V1::AppGlobalAPI
      # mount API::V1::BannersAPI
      # mount API::V1::QQLbsAPI
      # mount API::V1::ReportsAPI
      # mount API::V1::FeedbacksAPI
      # mount API::V1::AuthCodesAPI
      # mount API::V1::UsersAPI
      # mount API::V1::ShareAPI
      # # mount API::V1::MerchantsAPI
      # # mount API::V1::BannersAPI
      # # mount API::V1::PayAPI
      # mount API::V1::EarningsAPI
      # # mount API::V1::MessagesAPI
      # # mount API::V1::RedPacketsAPI
      # mount API::V1::FollowsAPI
      # mount API::V1::PagesAPI
      # # mount API::V1::EventsAPI
      # mount API::V1::RedbagsAPI
      # # mount API::V1::ItemsAPI
      # mount API::V1::LuckyDrawsAPI
      # mount API::V1::AttachmentsAPI
      # mount API::V1::OfferwallAPI
      
      # 
      # 配合trix文本编辑器
      # mount API::V1::AttachmentsAPI
      
      # 开发文档配置
      add_swagger_documentation(
          :api_version => "api/v1",
          hide_documentation_path: true,
          # mount_path: "/api/v1/api_doc",
          hide_format: true
      )
      
    end
  end
end