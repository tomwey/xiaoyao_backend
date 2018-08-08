module API
  module V1
    class HomeAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :entry, desc: '首页相关接口' do
        desc "获取首页数据接口"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '用户位置，格式为：(lng,lat)，例如：104.384747,30.4847373'
        end
        get do
          # 获取首页Banner
          @banners = Banner.opened.sorted.limit(5)
          
          # 获取正在进行的投票
          @vote = Vote.where(opened: true).first
          
          # # 获取功能模块
          # @sections = [
          #   {
          #     id: 1001,
          #     title: '艺人库',
          #     subtitle: '305位合作艺人'
          #   },
          #   {
          #     id: 1002,
          #     title: '梦想基金',
          #     subtitle: '已筹得20,000元'
          #   },
          #   {
          #     id: 1003,
          #     title: '吉他课堂',
          #     subtitle: '不断提升自己'
          #   }
          # ]
          # MV区块
          @media = Media.where(opened: true).order('sort desc').limit(3)
          @modules = [
            {
              name: '校园MV',
              list: API::V1::Entities::Media.represent(@media)
            }
          ]
          
          @performers = Performer.where(verified: true).limit(4)
          
          @user = User.find_by(private_token: params[:token])
          result = {
            banners: API::V1::Entities::Banner.represent(@banners),
            vote: API::V1::Entities::Vote.represent(@vote, { user: @user }),
            featured: @sections,
            # sections: @modules,
            performers: API::V1::Entities::Performer.represent(@performers, opts: { user: @user })
          }
          
          { code: 0, message: 'ok', data: result }
        end # end get /
      end # end resource
      
      resource :performs, desc: '艺人相关接口' do
        desc "获取艺人库"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :school, type: String, desc: '艺人学校'
          use :pagination
        end
        get do
          @performers = Performer.where(verified: true).order('id desc')
          if params[:page]
            @performers = @performers.paginate page: params[:page], per_page: page_size
            total = @performers.total_entries
          else
            total = @performers.size
          end
          render_json(@performers, API::V1::Entities::Performer, { user: User.find_by(private_token: params[:token]) }, total)
        end # get /
      end # end resource
      
    end # end class
  end
end