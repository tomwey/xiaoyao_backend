module API
  module V1
    class MerchantsAPI < Grape::API
      # 用户账号管理
      resource :account, desc: "注册登录接口" do
        desc "是否已经注册"
        params do
          requires :mobile,   type: String, desc: "用户手机号"
        end
        get :exists do
          # 手机号检查
          return render_error(1001, '不正确的手机号') unless check_mobile(params[:mobile])
          user = Merchant.find_by(mobile: params[:mobile])
          if user.blank?
            { code: 0, message: '账号还未注册' }
          else
            { code: 1, message: '账号已经注册' }
          end
        end # end check
        
        desc "用户注册"
        params do
          requires :mobile,   type: String, desc: "用户手机号"
          requires :password, type: String, desc: "密码"
          requires :code,     type: String, desc: "手机验证码"
        end
        post :signup do
          # 手机号检查
          return render_error(1001, '不正确的手机号') unless check_mobile(params[:mobile])
          
          # 是否已经注册检查
          user = User.find_by(mobile: params[:mobile])
          return render_error(1002, "#{params[:mobile]}已经注册") unless user.blank?
          
          # 密码长度检查
          return render_error(1003, "密码太短，至少为6位") unless params[:password].length >= 6
          
          # 检查验证码是否有效
          auth_code = AuthCode.check_code_for(params[:mobile], params[:code])
          return render_error(2004, '验证码无效') if auth_code.blank?
          
          # 注册
          user = User.create!(mobile: params[:mobile], password: params[:password], password_confirmation: params[:password])
          
          # 激活当前验证码
          auth_code.update_attribute(:activated_at, Time.now)
          
          # 绑定邀请
          inviter = User.find_by(nb_code: params[:invite_code])
          if inviter
            inviter.invite(user)
          end
          
          # 返回注册成功的用户
          render_json(user, API::V1::Entities::User)
        end # end post signup
        
        desc "用户登录"
        params do
          requires :mobile,   type: String, desc: "用户手机号，必须"
          requires :password, type: String, desc: "密码，必须"
        end
        post :login do
          # 手机号检测
          return render_error(1001, "不正确的手机号") unless check_mobile(params[:mobile])
          
          # 登录
          user = User.find_by(mobile: params[:mobile])
          return render_error(1004, "用户#{params[:mobile]}未注册") if user.blank?
          
          if user.authenticate(params[:password])
            render_json(user, API::V1::Entities::User)
          else
            render_error(1005, "登录密码不正确")
          end
        end # end post login
      end # end account resource
      
    end 
  end
end