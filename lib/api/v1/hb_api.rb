module API
  module V1
    class RedPacketsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :hb, desc: '红包相关接口' do
        desc "获取用户红包历史"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :histories do
          user = authenticate!
          
          @user_hbs = UserRedPacket.where(user_id: user.uid).where('opened_at is not null').order('opened_at desc')
          if params[:page]
            @user_hbs = @user_hbs.paginate page: params[:page], per_page: page_size
          end
          render_json(@user_hbs, API::V1::Entities::UserRedPacket)
        end # end histories
        
        desc "抢红包"
        params do
          requires :token,  type: String,  desc: '用户认证Token'
          requires :hbid,   type: String,  desc: '红包ID'
          requires :data,   type: JSON,    desc: '参与规则' # { event: { id: 123 }, rule: { type: quiz, question: '', answer: '' } }
        end
        post :grab do
          user = authenticate!
          
          klass = Object.const_get data.owner_type.to_s
          hbable = klass.find_by(uniq_id: data.owner_id)
          
          if hbable.blank?
            return render_error(4004, '未找到红包主体')
          end
          
          hb = Hongbao.find_by(uniq_id: params[:hbid], hbable: hbable)
          if hb.blank?
            return render_error(4004, '未找到红包')
          end
          
          # data = { owner_type: 'Event', owner_id: 22222, result: '' }
          # ruleable = hb.hbable.find_by(id: data.ruleable_id)
          result = hb.hbable.check_rule(result)
          if result['code'] != 0
            return result
          end
          
          
          
        end # end grab
        
      end # end resource
      
    end
  end
end