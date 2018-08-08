module API
  module V1
    class RedbagsAPI < Grape::API
      
      helpers API::SharedParams
      resource :hb, desc: '红包相关接口' do
        desc "获取一定数量最新的红包列表"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取数量，默认为20'
        end
        get :latest do
          size = (params[:size] || CommonConfig.max_latest_hb_size || 20).to_i
          
          @user ||= User.find_by(private_token: params[:token])
          
          @redbags = Redbag.opened.no_complete.not_share.sorted.order_by_left_money.latest.limit(size)
          
          render_json(@redbags, API::V1::Entities::Redbag, { user: @user })
        end # end get latest
        
        desc "获取发现红包列表"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取数量，默认为20'
        end
        get :explore do
          
          size = (params[:size] || CommonConfig.max_latest_hb_size || 20).to_i
          
          @user ||= User.find_by(private_token: params[:token])

          @redbags = Redbag.opened.no_complete.not_share.can_started.no_location_limit.sorted.order('updated_at desc')#.limit(size)

          # 获取3天内抢完的红包
          # redbag_ids2 = RedbagEarnLog.joins(%Q|LEFT JOIN redbag_earn_logs as e on e.user_id = redbag_earn_logs.user_id and redbag_earn_logs.created_at < e.created_at|).where('e.created_at is null').where('redbag_earn_logs.created_at > ?', Time.zone.now - 3.days).order('redbag_earn_logs.created_at desc').pluck('redbag_earn_logs.redbag_id')
          # if redbag_ids2.any?
          #   redbags = Redbag.opened.not_share.complete.no_location_limit.where(id: redbag_ids2)
          # else
          #   redbags = []
          # end

          render_json(@redbags, API::V1::Entities::Redbag, { user: @user })
        end # end get explore
        
        desc "获取附近的红包"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
          # optional :scope, type: Integer, desc: '范围，单位为米'
          # optional :size, type: Integer, desc: '数量'
        end
        get :nearby do
          # scope = (params[:scope] || 5000).to_i
          # size  = (params[:size] || 20).to_i
          
          @redbags = Redbag.opened.no_complete.not_share.can_started.sorted.nearby_distance(params[:lng], params[:lat]).order('updated_at desc, distance asc')#.limit(size)
          
          render_json(@redbags, API::V1::Entities::Redbag, { user: User.find_by(private_token: params[:token]) })
          # @events = Event.valid.nearby_distance(params[:lng], params[:lat], scope).sorted.order('id desc').limit(size)
          # render_json(@events, API::V1::Entities::Event)
        end # end get nearby
        
        desc "获取分享红包列表"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取数量，默认为20'
        end
        get :share do
          
          size = (params[:size] || CommonConfig.max_latest_hb_size || 20).to_i
          
          @user ||= User.find_by(private_token: params[:token])
          
          redbag_ids = RedbagEarnLog.where(user_id: @user.try(:id)).pluck(:redbag_id)
          
          @redbags = Redbag.opened.no_complete.not_share.where(id: redbag_ids).sorted.order('updated_at desc').limit(size)
          
          render_json(@redbags, API::V1::Entities::Redbag, { user: @user })
        end # end get share
        
        desc "获取任务红包列表"
        params do
          optional :token, type: String, desc: '用户Token'
          optional :loc,   type: String, desc: '用户位置，经纬度用英文逗号分隔，例如：102.0202,90.89282'
          use :pagination
        end
        get :task_list do
          # scope = (params[:scope] || 5000).to_i
          @redbags = Redbag.opened.no_complete.where(use_type: Redbag::USE_TYPE_TASK).no_location_limit.sorted.order('updated_at desc')
          
          user = User.find_by(private_token: params[:token])
          
          if params[:page]
            @redbags = @redbags.paginate page: params[:page], per_page: page_size
            total = @redbags.total_entries
            render_json(@redbags, API::V1::Entities::Redbag, { user: user }, total)
          else
            render_json(@redbags, API::V1::Entities::Redbag, { user: user })
          end
        end
        
        desc "获取红包详情"
        params do
          requires :id,    type: Integer, desc: '红包ID'
          optional :token, type: String,  desc: '用户TOKEN'
          optional :loc,   type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
          optional :t,     type: Integer, desc: '是否要记录浏览日志，默认值为1'
        end
        get '/:id/body' do
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          user = User.find_by(private_token: params[:token])
          
          # 写浏览日志
          t = (params[:t] || 1).to_i
          if t == 1
            @redbag.view_for(params[:loc], client_ip, user.try(:id))
          end

          render_json(@redbag, API::V1::Entities::RedbagDetail, { user: user })
        end #end get body
        
        desc "获取某个红包参与记录"
        params do
          requires :id, type: Integer, desc: '红包ID'
          use :pagination
        end
        get '/:id/earns' do
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          @earns = @redbag.redbag_earn_logs.where.not(money: 0.0).order('id desc')
          if params[:page]
            @earns = @earns.paginate page: params[:page], per_page: page_size
            total = @earns.total_entries
          else
            total = @earns.size
          end
          
          render_json(@earns, API::V1::Entities::RedbagEarnLog, {}, total)
          
        end # end get earns
        
        desc "获取红包所有者的主页信息"
        params do
          requires :id,    type: Integer, desc: '红包ID'
          optional :token, type: String,  desc: '用户TOKEN'
          optional :loc,   type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
        end 
        get '/:id/owner_timeline' do
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          @ownerable = @redbag.ownerable
          
          @hb_list = Redbag.opened.where(use_type: [Redbag::USE_TYPE_EVENT, Redbag::USE_TYPE_TASK]).where(ownerable: @ownerable).order('id desc')
          
          @total_sent = Redbag.opened.where(use_type: [Redbag::USE_TYPE_EVENT, Redbag::USE_TYPE_TASK]).where(ownerable: @ownerable).sum(:total_money).to_f
          @total_earn = @ownerable.try(:earn) || 0.00
          
          { code: 0, message: 'ok', data: { owner: {
            id: @ownerable.try(:uid) || @ownerable.try(:uniq_id),
            nickname: @ownerable.try(:format_nickname) || @ownerable.try(:name) || '',
            avatar: @ownerable.try(:real_avatar_url) || '',
            total_sent: @total_sent == 0 ? '0.00' : ('%.2f' % @total_sent),
            total_earn: @total_earn == 0 ? '0.00' : ('%.2f' % @total_earn),
          }, hb_list: API::V1::Entities::Redbag.represent(@hb_list) } }
        end # end get owner_info
        
        desc "获取我发布的红包"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :my_list do
          user = authenticate!
          
          # @events = user.events.order('id desc')
          
          @redbags = user.redbags.where(use_type: [Redbag::USE_TYPE_EVENT, Redbag::USE_TYPE_TASK]).order('id desc')
          
          if params[:page]
            @redbags = @redbags.paginate page: params[:page], per_page: page_size
            total = @redbags.total_entries
          else
            total = @redbags.size
          end
          render_json(@redbags, API::V1::Entities::MyRedbag, {}, total)
        end # get events
        
        desc "发红包"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          # requires :image,   type: Rack::Multipart::UploadedFile, desc: '图片二进制数据'
          requires :payload, type: JSON,   desc: 'JSON数据'
        end
        post :user_send do
          user = authenticate!
          
          payload = params[:payload]
          unless payload.is_a? Hashie::Mash
            return render_error(-1, '不正确的红包参数')
          end
          
          money = payload.total_money.to_f
          
          if money < 1.0 
            return render_error(-1, '红包金额最少1元')
          end
          
          if user.balance < money
            return render_error(-1, '余额不足，请先充值')
          end
          
          # { title: '', _type: 1, min_value: '', max_value: '', total_money: '', location: '104.1234,30.98765' }
          
          hb = Redbag.new
          hb.title = payload.title || '恭喜发财，大吉大利'
          hb._type = payload._type
          hb.min_value = payload.min_value
          hb.max_value = payload.max_value
          hb.total_money = payload.total_money
          hb.ownerable = user
          
          if payload.location.present? 
            hb.location   = "POINT(#{payload.location.gsub(',',' ')})"
          end
          
          hb.save!
          
          user.balance -= money
          user.save!
          
          render_json_no_data
          
        end # end post redbags
        
        desc "再次发起红包"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          # requires :owner,   type: JSON,   desc: '所有者信息，格式为：{ "type": ClassName, "id": 1 }'
          requires :payload, type: JSON,   desc: '红包信息，格式为：{ "type": 0, "total_money": 10, "min_value": 1, "max_value": 2 } 或 { "type": 1, "total": 10, "value": 1 }'
        end
        post '/:id/republish' do
          ownerable = authenticate!
          
          # 是否有没得红包
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          # 是否是自己的红包
          unless @redbag.ownerable == ownerable
            return render_error(-1, '非法操作')
          end
          
          payload = params[:payload]
          
          # 记录版本
          if RedbagVersion.where(redbag_id: @redbag.id).count == 0
            value = { _type: @redbag._type, 
                      total_money: @redbag.total_money,
                      min_value: @redbag.min_value,
                      max_value: @redbag.max_value
                     }
            RedbagVersion.create!(redbag_id: @redbag.id, value: value)
          end
          
          # 参数验证
          type = (payload.type || -1).to_i
          
          if type != 0 && type != 1
            return render_error(-1, '不正确的红包类型')
          end
          
          if type == 1
            value = (payload.value || 0).to_f
            if value <= 0
              return render_error(-1, '单个金额必须大于0元')
            end
            
            total = ( payload.total || 0 ).to_i
            if total <= 0
              return render_error(-1, '红包个数必须大于0')
            end
            
            min_value = value
            max_value = value
            total_money = total * value
            
          else
            min_value = ( payload.min_value || 0 ).to_f
            max_value = ( payload.max_value || 0 ).to_f
            total_money = ( payload.total_money || 0 ).to_f
          end
          
          if min_value <= 0
            return render_error(-1, '红包最小金额必须大于0元')
          end
          
          if max_value <= 0
            return render_error(-1, '红包最大金额必须大于0元')
          end
          
          if total_money <= 0
            return render_error(-1, '红包总金额必须大于0元')
          end
          
          if min_value > max_value
            return render_error(-1, '最小金额不能大于最大金额')
          end
          
          if max_value > total_money
            return render_error(-1, '最大金额不能大于总金额')
          end
          
          need_money = total_money
          
          # 分享红包处理
          share_hb = payload.share_hb
          if share_hb
            if share_hb.type == 0
              # 随机红包
              s_total_money = (share_hb.total_money || 0).to_f
              s_min_value   = (share_hb.min_value || 0).to_f
              s_max_value   = (share_hb.max_value || 0).to_f
            else
              # 固定红包
              s_total = (share_hb.total || 0).to_i
              s_value = (share_hb.value || 0).to_f
              
              s_total_money = s_total * s_value
              s_min_value = s_value
              s_max_value = s_value
            end
          else
            s_total_money = s_min_value = s_max_value = 0
          end
          
          # 判断是否有分享红包上传
          has_share_hb = (s_total_money > 0 && s_min_value > 0 && s_max_value > 0)
          
          if has_share_hb
            need_money += s_total_money  
          end
          
          if ownerable.balance < need_money
            return render_error(-1, '您的余额不足，请充值')
          end 
          
          @redbag._type = type
          @redbag.total_money += total_money
          @redbag.min_value = min_value
          @redbag.max_value = max_value
                    
          @redbag.save!
          
          # 扣除用户的钱
          ownerable.balance -= need_money
          ownerable.save!
          
          # 记录当前版本
          val = { _type: type, 
                  total_money: total_money,
                  min_value: min_value,
                  max_value: max_value
                  }
          lv1 = RedbagVersion.create!(redbag_id: @redbag.id, value: val)
          
          # 添加交易明细
          TradeLog.create!(tradeable: lv1, user_id: ownerable.id, money: total_money, title: '发布广告红包')
          
          if has_share_hb
            
            shb = Redbag.find_by(uniq_id: @redbag.share_hb.try(:uniq_id))
            
            # 记录分享红包之前的版本
            if shb
              if RedbagVersion.where(redbag_id: @redbag.share_hb.try(:id)).count == 0
                value = { _type: shb._type, 
                          total_money: shb.total_money,
                          min_value: shb.min_value,
                          max_value: shb.max_value
                         }
                RedbagVersion.create!(redbag_id: shb.id, value: value)
              end
              
              shb._type = share_hb.type
              shb.total_money += s_total_money
              shb.min_value = s_min_value
              shb.max_value = s_max_value
              
              shb.save!
              
              # 记录当前版本
              val = { _type: share_hb.type, 
                      total_money: s_total_money,
                      min_value: s_min_value,
                      max_value: s_max_value
                      }
              lv2 = RedbagVersion.create!(redbag_id: shb.id, value: val)
              
              # 添加交易明细
              TradeLog.create!(tradeable: lv2, user_id: ownerable.id, money: s_total_money, title: '发布分享红包')
            end
            
          end
          
          render_json(@redbag, API::V1::Entities::Redbag)
        end # end
        
        desc "浏览红包"
        params do
          optional :token,     type: String, desc: '用户Token'
          optional :from_type, type: Integer, desc: '来源类型'
          optional :loc,       type: String, desc: '经纬度，值用英文逗号分隔，例如：104.321231,90.3218393'
        end
        post '/:id/view' do
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          user = User.find_by(private_token: params[:token])
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          from_type = ( params[:from_type] || 0 ).to_i
          RedbagViewLog.create!(redbag_id: @redbag.id, user_id: user.try(:id), ip: client_ip, location: loc, from_type: from_type)
          render_json_no_data
          
        end # end post view
        
        desc "提交抢红包"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          requires :payload, type: JSON,   desc: '活动规则数据, 例如：{ "answer": "dddd" } 或 { "location": "30.12345,104.321234"}'
          optional :from_user, type: String, desc: '分享人的TOKEN'
        end
        post '/:id/commit' do
          user = authenticate!
          
          payload = params[:payload]
          
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          unless @redbag.opened
            return render_error(6001, '红包还没上架，不能抢')
          end
          
          if @redbag.started_at && @redbag.started_at > Time.zone.now
            return render_error(6001, '红包还未开抢')
          end
          
          # 判断是否红包还有       
          if @redbag.left_money <= 0
            return render_error(6001, '您下手太慢了，红包已经被抢完了！')
          end
          
          # 检查用户是否已经抢过
          if user.grabed?(@redbag)
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
          ruleable = @redbag.ruleable
          if ruleable
            result = ruleable.verify(payload)
            code = result[:code]
            message = result[:message]
            if code.to_i != 0
              if code.to_i == 6003
                # 答案不正确，也记录日志，用户不管对错，只有一次答题的机会
                RedbagEarnLog.create!(user_id: user.id, redbag_id: @redbag.id, money: 0.0, ip: client_ip, location: loc)
              end
              return { code: code, message: message }
            end
          end
          
          # 发红包
          money = @redbag.random_money
          if money <= 0.0
            return render_error(6001, '您下手太慢了，红包已经被抢完了！') 
          end
          
          # 发红包，记录日志
          earn_log = RedbagEarnLog.create!(user_id: user.id, redbag_id: @redbag.id, money: money, ip: client_ip, location: loc)
          
          # TODO: 如果有是通过分享获取的红包，并且该活动有分享红包，那么给分享人发一个分享红包
          if @redbag.share_hb
            from_user = User.find_by(private_token: params[:from_user])
            if from_user && from_user.verified && @redbag.share_hb.total_money > @redbag.share_hb.sent_money
              # 给分享人发分享红包
              if RedbagShareEarnLog.where(from_user_id: user.id, 
                                          redbag_id: @redbag.share_hb.id, 
                                          user_id: from_user.id).count == 0
                share_money = @redbag.share_hb.random_money
                if share_money > 0.0
                  RedbagShareEarnLog.create!(from_user_id: user.id, # 被分享人id
                                            redbag_id: @redbag.share_hb.id, 
                                            user_id: from_user.id, # 分享人id
                                            money: share_money)
                end # end send money
              end # 还没有得到过红包
            end # 可以发分享红包
          end # 如果设置了分享红包
          
          render_json(earn_log, API::V1::Entities::RedbagEarnLog)
        end # end post commit
        
        desc "分享红包回调"
        params do
          optional :token,   type: String, desc: '用户TOKEN'
          optional :loc,     type: String, desc: '经纬度，用英文逗号分隔，例如：104.00012,30.908838'
        end
        post '/:id/share' do
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          user = User.find_by(private_token: params[:token])
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          RedbagShareLog.create!(redbag_id: @redbag.id, user_id: user.try(:id), ip: client_ip, location: loc)
          render_json_no_data
          
        end # end share
        
        desc "点赞红包"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          optional :loc,     type: String, desc: '经纬度，用英文逗号分隔，例如：104.00012,30.908838'
        end
        post '/:id/like' do
          user = authenticate!
          
          @redbag = Redbag.find_by(uniq_id: params[:id])
          if @redbag.blank?
            return render_error(4004, '未找到红包')
          end
          
          if user.liked?(@redbag)
            return render_error(2002, '您已经赞过了')
          end
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          Like.create!(user_id: user.id, likeable: @redbag, ip: client_ip, location: loc)
          
          render_json_no_data
          
        end # end like        
      end # end events resource
      
    end
  end
end