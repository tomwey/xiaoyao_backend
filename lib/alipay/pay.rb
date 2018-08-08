require 'rest-client'
require 'openssl'
require 'base64'
module Alipay
  class Pay
    def self.pay(billno, mobile, name, money)
      params = {
        app_id: SiteConfig.alipay_app_id,
        method: 'alipay.fund.trans.toaccount.transfer',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        version: '1.0',
        biz_content: {
          out_biz_no: billno,
          payee_type: 'ALIPAY_LOGONID',
          payee_account: mobile,
          amount: (money / 100.0).to_s,
          payee_real_name: name || '',
          remark: '用户提现'
        }.to_json
      }
      
      params[:sign] = sign_params(params)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      # puts result
      if result['alipay_fund_trans_toaccount_transfer_response']
        code = result['alipay_fund_trans_toaccount_transfer_response']['code']
        if code && code.to_i == 10000
          if rsa_verify_result(result)
            return 0,'提现成功'
          else
            return 4001,'验证签名失败'
          end
        else
          return -2,result['alipay_fund_trans_toaccount_transfer_response']['sub_msg']
        end
      else
        return -1,'非法操作'
      end
      # {"alipay_fund_trans_toaccount_transfer_response"=>{"code"=>"10000", "msg"=>"Success", "order_id"=>"20171102110070001502230006316234", "out_biz_no"=>"201711021614212", "pay_date"=>"2017-11-02 16:14:52"}, "sign"=>"D8IkdbOCrncR3ps4UtYcBNQMx74R2M0iyDzX64L1LbkPeZR/DFxBXUHr9D9fFvLLVTEFTzpaMGF2iUxtTFLEPGZKhYb6dRPWHbFpztLdwMcuDKhuwvpSZR0YRRHIPWOhOmSII04K28TQOpdPI3rD9k5Z7GjiZNnuakKDVZUoPENPTsFdJrzRb/3rYAkX8wzaEzUKlQyUYt5sgVmZJQRCt3Xlr+UtPgAkkgwViu/+b4awQaBi1MTXmFGnKapK9y2d9q9B4BhDt+tzi9UADiUrD0VyjZ9PonO3hFYtLMG3WgkisTbbhIFYpzRvLeKLXxHYGzt3ld7TKdSARIqqWai9sw=="}
    end
    # 参数签名
    def self.sign_params(params)
      arr = params.sort
      hash = Hash[*arr.flatten]
      string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('&')
      # string
      key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/private_key.txt"))
      digest = OpenSSL::Digest::SHA256.new
      # puts string
      sign = key.sign(digest, string.force_encoding("utf-8"))
      # puts sign
      sign = Base64.encode64(sign)
      sign = sign.delete("\n").delete("\r")
      sign
    end
    
    # 验证签名
    def self.rsa_verify_result(result)
      alipay_result = result['alipay_fund_trans_toaccount_transfer_response'].to_json
      
      pub = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/alipay_public_key.txt"))
      digest = OpenSSL::Digest::SHA256.new
      
      sign = result['sign']
      # puts sign
      
      sign = Base64.decode64(sign)
      return pub.verify(digest, sign, alipay_result)
    end
    
    # 通知校验
    # def self.notify_verify?(params)
    #
    #   return false if params['appid'] != SiteConfig.wx_app_id
    #   return false if params['mch_id'] != SiteConfig.wx_mch_id
    #
    #   sign = params['sign']
    #   params.delete('sign')
    #   return sign_params(params) == sign
    #
    # end
  end
end