module API
  module V1
    class RedPacketsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :hb, desc: '红包相关接口' do
        desc "获取附近的红包"
        params do
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
          optional :scope, type: Integer, desc: '范围，单位为米'
          optional :limit, type: Integer, desc: '数量'
        end
        get :nearby do
          scope = (params[:scope] || 5000).to_i
          size  = (params[:limit] || 10).to_i
          @red_packets = RedPacket.opened.nearby_distance(params[:lng], params[:lat], scope).limit(size).sorted
          render_json(@red_packets, API::V1::Entities::RedPacket)
        end # end get nearby
        
        desc "获取红包列表"
        params do
          requires :lat, type: String, desc: '纬度'
          requires :lng, type: String, desc: '经度'
          use :pagination
        end
        get :list do
          scope = (params[:scope] || 5000).to_i
          @red_packets = RedPacket.opened.list_with_location(params[:lng], params[:lat]).sorted
          if params[:page]
            @red_packets = @red_packets.paginate page: params[:page], per_page: page_size
          end
          render_json(@red_packets, API::V1::Entities::RedPacket)
        end
        
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
        
        desc "获取红包结果详情"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          requires :hbid,  type: Integer, desc: '红包ID'
          use :pagination
        end
        get :results do
          user = authenticate!
          
          hb = RedPacket.find_by(oid: params[:hbid])
          if hb.blank?
            return render_error(4004, '没找到该红包')
          end
          
          user_hb = UserRedPacket.where(user_id: user.uid, hb_id: hb.oid).where('opened_at is not null').first
          
          opened_hbs = UserRedPacket.where('opened_at is not null').where(hb_id: hb.oid).order('opened_at desc, id desc')
          render_json(hb, API::V1::Entities::RedPacketResult, { user_hb: user_hb, opened_hbs: opened_hbs })
        end # end get results
        
        desc "获取抢红包商家主页"
        params do
          requires :token, type: String, desc: '用户认证Token'
          requires :hbid,  type: Integer, desc: '红包ID'
        end
        get :body do
          user = authenticate!
          
          hb = RedPacket.find_by(oid: params[:hbid])
          if hb.blank?
            return render_error(4004, '没找到该红包')
          end
          
          hb.add_hits
          
          render_json(hb, API::V1::Entities::RedPacketDetail, { user: user })
        end # end get body
        
        desc "抢红包"
        params do
          requires :token, type: String,  desc: '用户认证Token'
          requires :hbid,  type: Integer, desc: '红包ID'
        end
        post :grab do
          user = authenticate!
          
          hb = RedPacket.find_by(oid: params[:hbid])
          if hb.blank?
            return render_error(4004, '没找到该红包')
          end
          
          if hb.closed?
            return render_error(3002, '红包已收回')
          end
          
          if hb.expired?
            return render_error(3002, '红包已过期')
          end
          
          if hb.quantity - hb.open_count <= 0
            return render_error(3002, '手慢了，红包派完了')
          end
          
          user_hb = UserRedPacket.where(user_id: user.uid, hb_id: hb.oid).first
          if user_hb.blank?
            user_hb = UserRedPacket.create!(user_id: user.uid, hb_id: hb.oid, grabed_ip: client_ip, opened_ip: client_ip, grabed_at: Time.zone.now)
            
            if hb.has_ads
              # 如果该红包是有广告的，那么用户在抢的时候，就一定能获得红包，所以此时分配一个红包
              hb.open_count += 1
              hb.save!(validate: false)
            end
          elsif user_hb.opened_at.present?
            # 已经领取过红包，直接返回领取的红包详情
            # @hbs = UserRedPacket.where(hb_id: hb.oid).order('opened_at desc')
            # return render_json(@hbs, API::V1::Entities::UserRedPacket)
            return render_error(3005, '您已经领取了该红包！')
          end
          
          # 随机获取一个广告
          if hb.has_ads            
            @ad = Ad.where(opened: true).order('RANDOM()').first
            if @ad
              @ad.view_count += 1
              @ad.save!(validate: false)
            end
            user_hb.ad = @ad
          end
          
          render_json(user_hb, API::V1::Entities::UserRedPacket)
        end # end post grab
        
        desc "拆红包"
        params do
          requires :token, type: String,  desc: '用户认证Token'
          requires :hbid,  type: Integer, desc: '红包ID'
          # requires :oid,   type: String,  desc: '红包记录ID'
          optional :adid,  type: Integer, desc: '广告ID'
        end
        post :open do
          user = authenticate!
          
          hb = RedPacket.find_by(oid: params[:hbid])
          if hb.blank?
            return render_error(4004, '没找到该红包')
          end
          
          user_hb = UserRedPacket.where(user_id: user.uid, hb_id: hb.oid).first
          if user_hb.blank?
            return render_error(3004, '您还未抢过该红包，不能拆红包')
          end
          
          if user_hb.opened_at.present?
            # @hbs = UserRedPacket.where(hb_id: hb.oid).order('opened_at desc')
            # return render_json(@hbs, API::V1::Entities::UserRedPacket)
            return render_error(3005, '您已经领取了该红包！')
          end
          
          # 如果该红包没有广告，需要考虑红包是否已经关闭，过期，或者被领完了
          if not hb.has_ads
            if hb.closed?
              return render_error(3002, '红包已收回')
            end
          
            if hb.expired?
              return render_error(3002, '红包已过期')
            end
            
            if hb.quantity - hb.open_count <= 0
              return render_error(3002, '手慢了，红包领完了')
            end
            
            if hb.money - hb.open_money <= 0
              return render_error(3002, '手慢了，红包领完了')
            end
          end
          
          # 处理拆红包
          UserRedPacket.transaction do
            # 拆红包
            user_hb.opened_at = Time.zone.now
            user_hb.opened_ip = client_ip
            user_hb.money     = RedPacketService.getMoney(hb)
            user_hb.save!(validate: false)
            
            # 修改红包的信息
            if hb.has_ads
              hb.open_money += user_hb.money
            else
              hb.open_count += 1
              hb.open_money += user_hb.money
            end
            hb.save!(validate: false)
            
            # 更新用户的收益
            user.earn += user_hb.money
            user.balance += user_hb.money
            user.save!(validate: false)
            
            # 生成交易明细
            TradeLog.create!(user_id: user.id, tradeable: hb, money: user_hb.money, title: "红包-来自#{hb.owner_name}" )
          end
          
          # @hbs = UserRedPacket.where(hb_id: hb.oid).order('opened_at desc')
          # render_json(@hbs, API::V1::Entities::UserRedPacket)
          # user_hb = UserRedPacket.where(user_id: user.uid, hb_id: hb.oid).where('opened_at is not null').first
          
          opened_hbs = UserRedPacket.where('opened_at is not null').where(hb_id: hb.oid).order('opened_at desc, id desc')
          render_json(hb, API::V1::Entities::RedPacketResult, { user_hb: user_hb, opened_hbs: opened_hbs })
        end # end post grab
        
      end # end resource
      
    end
  end
end