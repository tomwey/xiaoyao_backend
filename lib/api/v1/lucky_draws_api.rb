module API
  module V1
    class LuckyDrawsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :cj, desc: '抽奖相关接口' do
        desc "获取抽奖详情"
        params do
          # requires :id,    type: Integer, desc: '红包ID'
          optional :token, type: String,  desc: '用户TOKEN'
          optional :loc,   type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
          optional :t,     type: Integer, desc: '是否要记录浏览日志，默认值为1'
        end 
        get '/:id/body' do
          @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
          if @lucky_draw.blank?
            return render_error(4004, '未找到该抽奖')
          end
          
          user = User.find_by(private_token: params[:token])
          
          # 写浏览日志
          t = (params[:t] || 1).to_i
          if t == 1
            @lucky_draw.view_for(params[:loc], client_ip, user.try(:id))
          end

          render_json(@lucky_draw, API::V1::Entities::LuckyDrawDetail, { user: user })
          
        end # end get body
        
        desc "开始抽奖"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
        end
        post '/:id/begin' do
          user = authenticate!
          
          @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
          if @lucky_draw.blank?
            return render_error(4004, '未找到该抽奖')
          end
          
          unless @lucky_draw.opened
            return render_error(6001, '抽奖活动还没上架')
          end
          
          if @lucky_draw.started_at && @lucky_draw.started_at > Time.zone.now
            return render_error(6001, '抽奖活动还未开始')
          end
          
          unless @lucky_draw.has_prizes?
            return render_error(6001, 'Oops, 已经全部抽完了')
          end
          
          unless user.can_prize?
            return render_error(6001, '对不起，您已经没有抽奖机会了')
          end
          
          # 检查用户是否已经抽过一次奖了，此处后期可以灵活考虑拿掉限制
          if user.prized?(@lucky_draw)
            return render_error(6001, '您已经参与过该抽奖')
          end
          
          prize = @lucky_draw.win_prize(user)
          if prize.blank?
            return render_error(6001, '对不起，没有找到奖品')
          end
          
          loc = params[:loc].blank? ? nil : "POINT(#{params[:loc].gsub(',', ' ')})"
          
          prize_log = LuckyDrawPrizeLog.create!(user_id: user.id, lucky_draw_id: @lucky_draw.id, prize_id: prize.id, ip: client_ip, location: loc)

          render_json(prize_log, API::V1::Entities::LuckyDrawPrizeLog)
          
        end # end post begin choujiang
        
        desc "获取抽奖结果记录"
        params do
          requires :id, type: Integer, desc: '红包ID'
          use :pagination
        end
        get '/:id/results' do
          @lucky_draw = LuckyDraw.find_by(uniq_id: params[:id])
          if @lucky_draw.blank?
            return render_error(4004, '未找到该抽奖')
          end
          
          @results = @lucky_draw.lucky_draw_prize_logs.includes(:user).order('id desc')
          if params[:page]
            @results = @results.paginate page: params[:page], per_page: page_size
            total = @results.total_entries
          else
            total = @results.size
          end
          
          render_json(@results, API::V1::Entities::LuckyDrawPrizeLog, {}, total)
        end # end get results
        
        desc "获取我的抽奖历史"
        params do 
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :my_list do
          user = authenticate!
          
          @lucky_draws = user.lucky_draws.order('id desc')
          
          if params[:page]
            @lucky_draws = @lucky_draws.paginate page: params[:page], per_page: page_size
            total = @lucky_draws.total_entries
          else
            total = @lucky_draws.size
          end
          render_json(@lucky_draws, API::V1::Entities::LuckyDraw, {}, total)
        end # end get my_list
        
      end # end resource
      
    end
  end
end