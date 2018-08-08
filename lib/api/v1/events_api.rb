module API
  module V1
    class EventsAPI < Grape::API
      
      helpers API::SharedParams
      resource :events, desc: '活动相关接口' do
        desc "获取一定数量最新的活动列表"
        params do
          optional :token, type: String, desc: '用户TOKEN'
          optional :loc,   type: String, desc: '位置坐标，格式为：lng,lat'
          optional :size,  type: Integer, desc: '获取数量，默认为20'
        end
        get :latest do
          size = (params[:size] || CommonConfig.max_latest_hb_size || 20).to_i
          @events = Event.joins(:hongbaos).where('events.current_hb_id = hongbaos.uniq_id and hongbaos.total_money != hongbaos.sent_money').valid.sorted.order('hongbaos.max_value desc, id desc').limit(size)
          render_json(@events, API::V1::Entities::Event)
        end # end get latest
        
        desc "获取附近的红包活动"
        params do
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
          optional :scope, type: Integer, desc: '范围，单位为米'
          optional :limit, type: Integer, desc: '数量'
        end
        get :nearby do
          scope = (params[:scope] || 5000).to_i
          size  = (params[:limit] || 10).to_i
          @events = Event.valid.nearby_distance(params[:lng], params[:lat], scope).sorted.order('id desc').limit(size)
          render_json(@events, API::V1::Entities::Event)
        end # end get nearby
        
        desc "获取红包活动列表"
        params do
          optional :token, type: String, desc: '用户Token'
          requires :lat,   type: String, desc: '纬度'
          requires :lng,   type: String, desc: '经度'
          use :pagination
        end
        get :list do
          scope = (params[:scope] || 5000).to_i
          @events = Event.joins(:hongbaos).where('events.current_hb_id = hongbaos.uniq_id').valid.range_of_data_for(params[:lng], params[:lat]).list_with_location(params[:lng], params[:lat]).select('(hongbaos.total_money - hongbaos.sent_money) as left_money').sorted.order('left_money desc, events.id desc')
            # .where('hongbaos.total_money != hongbaos.sent_money')
            
          # user = User.find_by(private_token: params[:token])
          user = User.find_by(private_token: params[:token])
          
          if params[:page]
            @events = @events.paginate page: params[:page], per_page: page_size
            total = @events.total_entries
            render_json(@events, API::V1::Entities::Event, { user: user }, total)
          else
            render_json(@events, API::V1::Entities::Event, { user: user })
          end
        end
        
        desc "获取活动详情"
        params do
          requires :event_id, type: Integer, desc: '活动ID'
          optional :size,     type: Integer, desc: '第一页活动记录数据大小，默认为20'
          optional :token,    type: String,  desc: '用户TOKEN'
          optional :loc,      type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
          # optional :token,    type: String, desc: '用户Token'
        end
        get '/:event_id/body' do
          @event = Event.find_by(uniq_id: params[:event_id])
          if @event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          # 写浏览日志
          loc = nil
          if params[:loc]
            lng,lat = params[:loc].split(',')
            loc = "POINT(#{lng} #{lat})"
          end
          EventViewLog.create!(event_id: @event.id, ip: client_ip, user_id: User.find_by(private_token: params[:token]).try(:uid), location: loc)
          user = User.find_by(private_token: params[:token])
          
          @event.latest_log_size = ( params[:size] || 20 ).to_i
          render_json(@event, API::V1::Entities::EventDetail, { user: user })
        end #end get body
        
        desc "获取活动所有者的信息以及发布过的红包信息"
        params do
          requires :event_id, type: Integer, desc: '活动ID'
          optional :token,    type: String,  desc: '用户TOKEN'
          optional :loc,      type: String,  desc: '经纬度，用英文逗号分隔，例如：104.213222,30.9088273'
        end 
        get '/:event_id/owner_info' do
          @event = Event.find_by(uniq_id: params[:event_id])
          if @event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          @ownerable = @event.ownerable
          
          @events = Event.valid.where(ownerable: @ownerable).order('id desc')
          
          @ids = Event.valid.where(ownerable: @ownerable).pluck(:id)
          
          @total_sent = Hongbao.where(event_id: @ids, use_type: Hongbao::USE_TYPE_BASE).sum(:total_money).to_f
          @total_earn = @ownerable.try(:earn) || 0.00
          
          { code: 0, message: 'ok', data: { owner: {
            id: @ownerable.try(:uid) || @ownerable.try(:uniq_id),
            nickname: @ownerable.try(:format_nickname) || @ownerable.try(:name) || '',
            avatar: @ownerable.try(:real_avatar_url) || '',
            total_sent: @total_sent == 0 ? '0.00' : ('%.2f' % @total_sent),
            total_earn: @total_earn == 0 ? '0.00' : ('%.2f' % @total_earn),
          }, events: API::V1::Entities::Event.represent(@events) } }
        end # end get owner_info
        
        desc "获取我发布的活动"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get do
          user = authenticate!
          
          @events = user.events.order('id desc')
          if params[:page]
            @events = @events.paginate page: params[:page], per_page: page_size
            total = @events.total_entries
          else
            total = @events.size
          end
          render_json(@events, API::V1::Entities::Event, {}, total)
        end # get events
        
        desc "发布活动"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          requires :image,   type: Rack::Multipart::UploadedFile, desc: '图片二进制数据'
          requires :payload, type: JSON,   desc: 'JSON数据'
        end
        post do
          user = authenticate!
          
          payload = params[:payload]
          unless payload.is_a? Hashie::Mash
            return render_error(-1, '不正确的payload参数')
          end
          
          money = payload.hb.total_money.to_f
          
          if money < 2.0 
            return render_error(-1, '红包金额最少2元')
          end
          
          if user.balance < money
            return render_error(-1, '发布红包活动失败，余额不足')
          end
          
          # puts payload
          
          # { title: '', image: '', body: '', body_url: '', hb: { _type: 1, min_value: '', max_value: '', total_money: '' }, started_at: '', location:'' ,range: '', rule: { name: 'quiz', data: { question: '', answers:'', answer: '' } } }
          # { type: 'Quiz', question: '', answer: '', answers: '' }
          # { type: 'Checkin', address: '', location: '', accuracy: '' }
          # payload
          # class_name = "#{payload.rule.type.capitalize}Rule"
          # klass = Object.get_const class_name
          # ruleable = klass.create!(payload.rule.data)
          if payload.rule.type == 'Quiz'
            ruleable = QuizRule.new
            ruleable.question = payload.rule.question
            ruleable.answer   = payload.rule.answer
            ruleable.answers  = payload.rule.answers.split(',')
            ruleable.save!
          elsif payload.rule.type == 'Checkin'
            ruleable = CheckinRule.new
            ruleable.address = payload.rule.address
            ruleable.location   = "POINT(#{payload.rule.location})"
            ruleable.accuracy  = payload.rule.accuracy
            ruleable.save!
          end
          
          hb = Hongbao.new
          hb._type = payload.hb._type
          hb.min_value = payload.hb.min_value
          hb.max_value = payload.hb.max_value
          hb.total_money = payload.hb.total_money
          hb.operator_type = user.class.to_s
          hb.operator_id   = user.id
          
          hb.save!
          
          event = Event.new
          event.title = payload.title
          event.image = params[:image]
          event.body  = payload.body
          event.body_url = payload.body_url
          event.current_hb_id = hb.uniq_id
          event.started_at = payload.started_at
          event.location = "POINT(#{payload.location})"
          event.range = payload.range
          event.ruleable = ruleable
          event.ownerable = user
          
          event.save!
          
          user.balance -= money
          user.save!
          
          # 保存event的uniq_id到规则表
          event.ruleable.event_id = event.uniq_id
          event.ruleable.save!
          
          # 更新当前红包的活动id
          hb.event_id = event.id
          hb.save!
          
          render_json_no_data
          
          # payload
          
        end # end post events
        
        desc "重新发布活动"
        params do
          requires :token,  type: String, desc: '用户TOKEN'
          requires :payload, type: JSON,   desc: 'JSON数据'
        end
        post '/:event_id/republish' do
          user = authenticate!
          
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          if user != event.ownerable
            return render_error(-1, '非法操作!')
          end
          
          # 如果当前红包还没抢完，那么不能重新发布红包
          if event.current_hb && event.current_hb.total_money > event.current_hb.sent_money
            return render_error(-2, '还有未抢完的红包，不能再次发布')
          end
          
          payload = params[:payload]
          unless payload.is_a? Hashie::Mash
            return render_error(-1, '不正确的payload参数')
          end
          
          money = payload.hb.total_money.to_f
          
          if money < 2.0 
            return render_error(-1, '红包金额最少2元')
          end
          
          if user.balance < money
            return render_error(-1, '发布红包活动失败，余额不足')
          end
          
          if payload.hb
            # 创建红包
            hb = Hongbao.new
            hb._type = payload.hb._type
            hb.min_value = payload.hb.min_value
            hb.max_value = payload.hb.max_value
            hb.total_money = payload.hb.total_money
            hb.operator_type = user.class.to_s
            hb.operator_id   = user.id
            hb.event_id = event.id
            
            hb.save!
            
            event.current_hb_id = hb.uniq_id
          end
          
          # 创建规则
          if payload.rule
            # 保存已存在的规则活动id
            if event.ruleable.event_id.blank?
              event.ruleable.event_id = event.uniq_id
              event.ruleable.save
            end
            
            if payload.rule.type == 'Quiz'
              ruleable = QuizRule.new
              ruleable.question = payload.rule.question
              ruleable.answer   = payload.rule.answer
              ruleable.answers  = payload.rule.answers.split(',')
              ruleable.event_id = event.uniq_id
              ruleable.save!
            elsif payload.rule.type == 'Checkin'
              ruleable = CheckinRule.new
              ruleable.address = payload.rule.address
              ruleable.location   = "POINT(#{payload.rule.location})"
              ruleable.accuracy  = payload.rule.accuracy
              ruleable.event_id = event.uniq_id
              ruleable.save!
            end
          
            event.ruleable = ruleable
          end
          
          event.save!
                    
          render_json_no_data
          
        end # end post republish
        
        desc "提交活动"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          requires :payload, type: JSON,   desc: '活动规则数据, 例如：{ "answer": "dddd" } 或 { "location": "30.12345,104.321234"}'
          optional :from_user, type: String, desc: '分享人的TOKEN'
        end
        post '/:event_id/commit' do
          user = authenticate!
          
          payload = params[:payload]
          
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          if event.pending? or event.rejected?
            return render_error(6001, '活动还未审核通过，不能抢红包')
          end
          
          if event.started_at && event.started_at > Time.zone.now
            return render_error(6001, '红包还未开抢')
          end
          
          # 用户位置
          if payload.location
            lat,lng = payload.location.split(',')
            loc = "POINT(#{lng} #{lat})"
          else
            loc = nil
          end
          
          hb = event.current_hb
          if hb.blank?
            return render_error(-2, '活动没有红包，无效的活动')
          end
          
          if hb.left_money <= 0
            return render_error(6001, '您下手太慢了，红包已经被领完了！')
          end
          
          event_earn = EventEarnLog.where(user_id: user.id, event_id: event.id, hb_id: hb.uniq_id).first
          if event_earn.present?
            return render_error(6006, '您已经领取了该活动红包，不能重复参与')
          end
          
          ruleable = event.ruleable
          if ruleable.present? 
            result = ruleable.verify(payload)
            code = result[:code]
            message = result[:message]
            if code.to_i != 0
              if code.to_i == 6003
                # 答案不正确，也记录日志，用户不管对错，只有一次答题的机会
                EventEarnLog.create!(user_id: user.id, event_id: event.id, hb_id: hb.uniq_id, money: 0.0, ip: client_ip, location: loc)
              end
              return { code: code, message: message }
            end
          end
          
          # 发红包
          money = hb.random_money
          if money <= 0.0
            return render_error(6001, '您下手太慢了，红包已经被领完了！') 
          end
          # puts money
          event_earn = EventEarnLog.create!(user_id: user.id, event_id: event.id, hb_id: hb.uniq_id, money: money, ip: client_ip, location: loc)
          
          # 如果有是通过分享获取的红包，并且该活动有分享红包，那么给分享人发一个分享红包
          if event.share_hb_id.present?
            share_hb = event.share_hb
            from_user = User.find_by(private_token: params[:from_user])
            if from_user && from_user.verified && share_hb && share_hb.total_money > share_hb.sent_money
              # 给分享人发分享红包
              if EventShareEarnLog.where(for_user_id: user.id, event_id: event.id, hb_id: share_hb.uniq_id, user_id: from_user.id).count == 0
                share_money = share_hb.random_money
                if share_money > 0.0
                  EventShareEarnLog.create!(for_user_id: user.id, # 被分享人id
                                            event_id: event.id, 
                                            hb_id: share_hb.uniq_id, 
                                            user_id: from_user.id, # 分享人id
                                            money: share_money)
                end
              end
            end
          end
          
          render_json(event_earn, API::V1::Entities::EventEarnLog)
        end # end post commit
        
        desc "分享活动回调"
        params do
          optional :token,   type: String, desc: '用户TOKEN'
          optional :loc,     type: String, desc: '经纬度，用英文逗号分隔，例如：104.00012,30.908838'
        end
        post '/:event_id/share' do
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          user = User.find_by(private_token: params[:token])
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          EventShareLog.create!(event_id: event.id, user_id: user.try(:uid), ip: client_ip, location: loc)
          
          render_json_no_data
          
        end # end share
        
        desc "点赞活动"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          optional :loc,     type: String, desc: '经纬度，用英文逗号分隔，例如：104.00012,30.908838'
        end
        post '/:event_id/like' do
          user = authenticate!
          
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          if user.liked?(event)
            return render_error(2002, '您已经赞过了')
          end
          
          loc = nil
          if params[:loc]
            loc = params[:loc].gsub(',', ' ')
            loc = "POINT(#{loc})"
          end
          
          Like.create!(user_id: user.id, likeable: event, ip: client_ip, location: loc)
          
          render_json_no_data
          
        end # end like
        
        desc "获取某个活动的活动参与记录"
        params do
          requires :event_id, type: Integer, desc: '活动ID'
          use :pagination
        end
        get '/:event_id/earns' do
          event = Event.find_by(uniq_id: params[:event_id])
          if event.blank?
            return render_error(4004, '未找到该活动')
          end
          
          @earns = event.event_earn_logs.where.not(money: 0.0).order('id desc')
          if params[:page]
            @earns = @earns.paginate page: params[:page], per_page: page_size
            total = @earns.total_entries
          else
            total = @earns.size
          end
          
          render_json(@earns, API::V1::Entities::EventEarnLog, {}, total)
          
        end # end get earns
        
      end # end events resource
      
    end
  end
end