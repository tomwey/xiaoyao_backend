module API
  module V1
    class WithdrawsAPI < Grape::API
      
      helpers API::SharedParams
      
      resource :user, desc: '用户相关接口，绑定微信公众号' do
        desc '绑定提现账号到微信公众号'
        params do
          requires :token, type: String, desc: '用户Token'
          requires :code,  type: String, desc: '微信验证码'
        end
        post :bind_wechat do
          user = authenticate!
          
          code = WeixinAuthCode.where(code: params[:code]).first
          
          if code.blank?
            return render_error(4004, '微信验证码无效')
          end
          
          if code.expired?
            return render_error(7001, '微信验证码已过期')
          end
          
          if code.user_id.present?
            return render_error(7002, '该验证码已经绑定了一个用户')
          end
          
          code.user_id = user.id
          code.save!
          
          render_json_no_data
        end # end post
      end # end resource
      
      resource :withdraws, desc: '提现相关接口' do
        desc '获取提现方式'
        params do
          requires :token, type: String, desc: '用户Token'
        end
        get :pay_list do
          user = authenticate!
          
          json = []
          
          %w(微信提现 支付宝提现).each_with_index do |item, index|
            type = index + 1
            account = WithdrawAccount.where(user_id: user.id, account_type: type).first
            hash = { name: item, type: type }
            if account.present?
              if account.account_type == 1
                temp = { account_id: account.id, account_name: account.name || "" }
              elsif account.account_type == 2
                temp = { account_id: account.id, account_name: account.name, account_num: account.account_id }
              end
              hash[:account_info] = temp || {}
            end
            
            json << hash
          end
          
          { code: 0, message: 'ok', data: json }
          
        end # end get pay_list
        
        desc "获取提现记录"
        params do
          requires :token, type: String, desc: '用户Token'
          use :pagination
        end
        get :list do
          user = authenticate!
          
          @withdraws = Withdraw.where(user_id: user.id).order('id desc')
          if params[:page]
            @withdraws = @withdraws.paginate page: params[:page], per_page: page_size
          end
          
          render_json(@withdraws, API::V1::Entities::Withdraw)
        end # end get list
        
        desc "创建提现申请"
        params do
          requires :token,        type: String,  desc: "用户Token"
          # requires :pay_password, type: String,  desc: "支付密码"
          requires :account_type, type: Integer, desc: '提现方式，1为微信提现，2为支付宝提现'
          requires :account_name, type: String,  desc: '账号名，支付宝账号姓名或者微信支付绑定的银行卡姓名'
          optional :account_num,  type: String,  desc: '提现账号, 如果是微信提现，那么可以不传该参数，如果是支付宝提现，那必须传该参数'
          requires :beans,        type: Integer, desc: '提现益豆数'
        end
        post :create do
          user = authenticate!
          
          account_type = params[:account_type]
          
          fee = CommonConfig.send("withdraw_fee_#{account_type}") || 0
          total = params[:beans] + fee
          
          return render_error(8001, '余额不足') if total > user.balance
          
          # TODO:检测支付密码
          
          if account_type == 1
            # 微信提现
            # 能执行提交，那么微信提现账号已经存在
            @account = WithdrawAccount.where(user_id: user.id, account_type: 1).first
            
            return render_error(4004, '还没有绑定微信账号') if @account.blank?
            
            # 检测是否已经激活了账号
            auth_code = WeixinAuthCode.where(user_id: user.id, openid: @account.account_id).first
            if auth_code.blank? or (!auth_code.actived?)
              return render_error(8002, '还没有激活提现账号，请到微信公众号进行激活操作')
            end
            
            if params[:account_name] && params[:account_name] != @account.name
              @account.name = params[:account_name]
              @account.save!
            end
          elsif account_type == 2
            # 支付宝提现
            # 有可能支付宝账号还未创建
            
            return render_error(-1, '支付宝提现，必须传account_num参数') if params[:account_num].blank?
            
            @account = WithdrawAccount.where(user_id: user.id, account_type: 2).first
            if @account.blank?
              @account = WithdrawAccount.create!(user_id: user.id, account_type: 2, account_id: params[:account_num], name: params[:account_name])
            else
              if params[:account_name] && params[:account_name] != @account.name
                @account.name = params[:account_name]
              end
              
              if params[:account_num] && params[:account_num] != @account.account_id
                @account.account_id = params[:account_num]
              end
              
              @account.save!
              
            end # end if
          end
          
          Withdraw.create!(user_id: user.id, account_name: @account.name, account_num: @account.account_id, bean: params[:beans], fee: fee, account_type: account_type)
          
          render_json_no_data
          
        end # end post create
        
      end # end resource
      
    end
  end
end