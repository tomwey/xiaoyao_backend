module API
  module V1
    class ItemsAPI < Grape::API
      
      helpers API::SharedParams
      resource :ev, desc: '活动相关接口' do

        desc "获取发现红包活动列表"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取数量，默认为20'
        end
        get :explore do
          
          size = (params[:size] || CommonConfig.max_latest_hb_size || 20).to_i
          
          @user ||= User.find_by(private_token: params[:token])

          @items = Item.includes(:item_content).opened.no_complete.no_location_limit.sorted.order('items.updated_at desc')

          render_json(@items, API::V1::Entities::Item, { user: @user })
        end # end get explore
        
        desc "获取附近的红包活动"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
          # optional :scope, type: Integer, desc: '范围，单位为米'
          # optional :size, type: Integer, desc: '数量'
        end
        get :nearby do
          @items = Item.includes(:item_content).opened.nearby_distance(params[:lng], params[:lat]).no_complete.sorted.order('items.updated_at desc, distance asc')#.limit(size)
          
          render_json(@items, API::V1::Entities::Item, { user: User.find_by(private_token: params[:token]) })
        end # end get nearby
        
        desc "获取红包活动详情"
        params do
          requires :id,    type: Integer, desc: '红包ID'
          optional :token, type: String,  desc: '用户TOKEN'
          optional :loc,   type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
          optional :t,     type: Integer, desc: '是否要记录浏览日志，默认值为1'
        end
        get '/:id/body' do
          @item = Item.find_by(uniq_id: params[:id])
          if @item.blank?
            return render_error(4004, '未找到活动')
          end
          
          user = User.find_by(private_token: params[:token])
          
          # 写浏览日志
          t = (params[:t] || 1).to_i
          if t == 1
            @item.view_for(params[:loc], client_ip, user.try(:id))
          end

          render_json(@item, API::V1::Entities::ItemDetail, { user: user })
        end #end get body
        
        desc "获取某个红包参与记录"
        params do
          requires :id, type: Integer, desc: '红包ID'
          use :pagination
        end
        get '/:id/earns' do
          @item = Item.find_by(uniq_id: params[:id])
          if @item.blank?
            return render_error(4004, '未找到红包')
          end
          
          @earns = @item.item_win_logs.where.not(resultable: nil).order('id desc')
          if params[:page]
            @earns = @earns.paginate page: params[:page], per_page: page_size
            total = @earns.total_entries
          else
            total = @earns.size
          end
          
          render_json(@earns, API::V1::Entities::ItemWinLog, {}, total)
          
        end # end get earns
        
        desc "获取红包所有者的主页信息"
        params do
          requires :id,    type: Integer, desc: '红包ID'
          optional :token, type: String,  desc: '用户TOKEN'
          optional :loc,   type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
        end 
        get '/:id/owner_timeline' do
          @item = Item.find_by(uniq_id: params[:id])
          if @item.blank?
            return render_error(4004, '未找到红包')
          end
          
          @ownerable = @item.ownerable
          
          @hb_list = Item.opened.where(ownerable: @ownerable).order('id desc')
          
          ids = Item.opened.where(ownerable: @ownerable).pluck(:id)
          @total_sent = ItemPrize.where(item_id: ids, prizeable_type: 'Redbag').sum(:total_money).to_f
          
          @total_earn = @ownerable.try(:earn) || 0.00
          
          { code: 0, message: 'ok', data: { owner: {
            id: @ownerable.try(:uid) || @ownerable.try(:uniq_id),
            nickname: @ownerable.try(:format_nickname) || @ownerable.try(:name) || '',
            avatar: @ownerable.try(:real_avatar_url) || '',
            total_sent: @total_sent == 0 ? '0.00' : ('%.2f' % @total_sent),
            total_earn: @total_earn == 0 ? '0.00' : ('%.2f' % @total_earn),
          }, hb_list: API::V1::Entities::Item.represent(@hb_list) } }
        end # end get owner_info
        
        desc "获取我发布的红包"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :my_list do
          user = authenticate!
          
          @items = Item.where(ownerable: user).order('id desc')
          
          if params[:page]
            @items = @items.paginate page: params[:page], per_page: page_size
            total = @items.total_entries
          else
            total = @items.size
          end
          render_json(@items, API::V1::Entities::Item, {}, total)
        end # get events
        
        desc "提交抢红包"
        params do
          requires :token,     type: String, desc: '用户TOKEN'
          requires :payload,   type: JSON,   desc: '活动规则数据, 例如：{ "answer": "dddd" } 或 
                                                                   { "location": "30.12345,104.321234"}'
          optional :from_user, type: String, desc: '分享人的TOKEN'
        end
        post '/:id/commit' do
          user = authenticate!
          
          payload = params[:payload]
          
          @item = Item.find_by(uniq_id: params[:id])
          if @item.blank?
            return render_error(4004, '未找到红包')
          end
          
          unless @item.opened
            return render_error(6001, '红包还没上架，不能抢')
          end
          
          if @item.started_at && @item.started_at > Time.zone.now
            return render_error(6001, '红包还未开抢')
          end
          
          # 判断是否红包还有  
          if not @item.can_prize?
            return render_error(6001, '您下手太慢了，红包已经被抢完了！')
          end
          
          # 检查用户是否已经抢过
          if user.grabed_item?(@item)
            return render_error(6006, '您已经领取了该活动红包，不能重复参与')
          end
          
          # 用户位置
          if payload[:location]
            lng,lat = payload[:location].split(',')
            loc = "POINT(#{lng} #{lat})"
          else
            loc = nil
          end
          
          # 验证红包规则
          ruleable = @item.ruleable
          if ruleable
            result = ruleable.verify(payload)
            code = result[:code]
            message = result[:message]
            if code.to_i != 0
              if code.to_i == 6003
                # 答案不正确，也记录日志，用户不管对错，只有一次答题的机会
                ItemWinLog.create!(user_id: user.id, 
                                   item_id: @item.id, 
                                   resultable: nil, 
                                   ip: client_ip, 
                                   location: loc)
              end
              return { code: code, message: message }
            end
          end
          
          # 随机一个红包奖励
          @prize = @item.send_prize
          if @prize.blank?
            return render_error(6001, '您下手太慢了，红包已经被抢完了！')
          end
          
          render_json_no_data
          
          # if @resultable = @prize.send_to_user(user, client_ip, loc)
          #   log = ItemWinLog.create!(user_id: user.id,
          #                            item_id: @item.id,
          #                            resultable: @resultable,
          #                            ip: client_ip,
          #                            location: loc)
          #   render_json(@log, API::V1::Entities::ItemWinLog)
          # else
          #   render_error(6001, '提交红包出错了')
          # end
          # # 发红包，记录日志
          # earn_log = RedbagEarnLog.create!(user_id: user.id, redbag_id: @redbag.id, money: money, ip: client_ip, location: loc)
          #
          # # TODO: 如果有是通过分享获取的红包，并且该活动有分享红包，那么给分享人发一个分享红包
          # if @redbag.share_hb
          #   from_user = User.find_by(private_token: params[:from_user])
          #   if from_user && from_user.verified && @redbag.share_hb.total_money > @redbag.share_hb.sent_money
          #     # 给分享人发分享红包
          #     if RedbagShareEarnLog.where(from_user_id: user.id,
          #                                 redbag_id: @redbag.share_hb.id,
          #                                 user_id: from_user.id).count == 0
          #       share_money = @redbag.share_hb.random_money
          #       if share_money > 0.0
          #         RedbagShareEarnLog.create!(from_user_id: user.id, # 被分享人id
          #                                   redbag_id: @redbag.share_hb.id,
          #                                   user_id: from_user.id, # 分享人id
          #                                   money: share_money)
          #       end # end send money
          #     end # 还没有得到过红包
          #   end # 可以发分享红包
          # end # 如果设置了分享红包
          #
          # render_json(earn_log, API::V1::Entities::RedbagEarnLog)
        end # end post commit
        
        desc "分享红包回调"
        params do
          optional :token,   type: String, desc: '用户TOKEN'
          optional :loc,     type: String, desc: '经纬度，用英文逗号分隔，例如：104.00012,30.908838'
        end
        post '/:id/share' do
          @item = Item.find_by(uniq_id: params[:id])
          if @item.blank?
            return render_error(4004, '未找到红包')
          end
          
          user = User.find_by(private_token: params[:token])
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          ItemShareLog.create!(item_id: @item.id, user_id: user.try(:id), ip: client_ip, location: loc)
          render_json_no_data
          
        end # end share
               
      end # end events resource
      
    end
  end
end