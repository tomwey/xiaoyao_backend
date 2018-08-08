require 'rest-client'
module API
  module V1
    class AuthCodesAPI < Grape::API
      
      resource :auth_codes, desc: "验证码接口" do
        desc "生成验证码"
        params do
          requires :mobile, type: String, desc: "手机号，必须"
          optional :code_length, type: Integer, desc: "验证码长度，4-6位，默认为4"
        end
        post do
          mobile = params[:mobile].to_s
        
          return render_error(1001, "不正确的手机号") unless check_mobile(mobile)
          
          # 1分钟内多次发送验证码短信检测
          key = "#{mobile}_key".to_sym
          if session[key] and ( ( Time.now.to_i - session[key].to_i ) < ( 60 + rand(3) ) )
            return render_error(2001, "同一手机号1分钟内只能获取一次验证码，请稍后重试")
          end
          session[key] = Time.now.to_i
          ###### end
          
          # 同一手机一天最多获取5次验证码
          log = SendSmsLog.where(mobile: mobile).first
          if log.blank?
            dt = 0
            log = SendSmsLog.create!(mobile: mobile, first_sent_at: Time.now)
          else
            dt = Time.now.to_i - log.first_sent_at.to_i
          
            if dt > 24 * 3600 # 超过24小时重置发送记录
              log.send_total = 0
              log.first_sent_at = Time.now
              log.save!
            else
              # 24小时以内
              if log.send_total.to_i == 5 # 已经发送了5次
                return render_error(2002, "同一手机号24小时内只能获取5次验证码，请稍后再试")
              end
            end # end 24小时check
          end
          
          # 获取验证码
          code_length = params[:code_length].to_i
          length = [code_length, 4].max
          length = [length, 6].min
          
          code = AuthCode.where('mobile = ? and activated_at is null', mobile).first
          if code.blank? or code.code.length != length
            code = AuthCode.create_code!(mobile, length)
          end
          return render_error(2003, "验证码生成错误，请重试") if code.blank?
          
          # 发送短信
          tpl = "您的验证码是{code}【{company}】"
          text = tpl.gsub('{code}', "#{code.code}")
          text = text.gsub('{company}', "#{SiteConfig.company}")
          RestClient.post("#{SiteConfig.sp_url}", "apikey=#{SiteConfig.sp_api_key}&mobile=#{mobile}&text=#{text}") { |response, request, result, &block|
            resp = JSON.parse(response)
            if resp['code'] == 0
              # 发送成功，更新发送日志
              log.update_attribute(:send_total, log.send_total + 1)
              { code: 0, message: "ok" }
            else
              # 发送失败，更新每分钟发送限制
              session.delete(key)
              { code: -1, message: resp['msg'] }
            end
          }
          
        end # end post
      end # end resource
      
    end
  end
end