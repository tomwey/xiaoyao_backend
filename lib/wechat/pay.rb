require 'rest-client'
module Wechat
  class Pay
    # 统一下单
    def self.unified_order(order, ip)
      return false if order.blank?
      
      total_fee = SiteConfig.wx_pay_debug == 'true' ? '1' : "#{order.money}"
      params = {
        appid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        device_info: 'WEB',
        nonce_str: SecureRandom.hex(16),
        body: "账号充值",
        out_trade_no: order.uniq_id,
        total_fee: total_fee,
        spbill_create_ip: ip,
        notify_url: SiteConfig.wx_pay_notify_url,
        trade_type: 'MWEB',#'JSAPI', # JSAPI 表示微信公众号支付 # MWEB 表示微信H5支付
        openid: order.wx_auth_profile.try(:openid) || '',
        attach: '支付订单'
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      result = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      # puts pay_result
      
      #####################################################
      # 此结果是微信H5支付返回的结果
      # {"return_code"=>"SUCCESS", "return_msg"=>"OK", "appid"=>"wxb0463c984a911d20", "mch_id"=>"1482457452", "device_info"=>"WEB", "nonce_str"=>"aawIACsVCELxKK9Y", "sign"=>"DE2789A6040732DE1B7551277B4840ED", "result_code"=>"SUCCESS", "prepay_id"=>"wx31213745522221cfe8f701d40376561980", "trade_type"=>"MWEB", "mweb_url"=>"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx31213745522221cfe8f701d40376561980&package=1359601095"}
      #####################################################
      
      return pay_result
    end
    
    # 统一下单
    def self.wx_unified_order(order, ip, is_wx_browser)
      return false if order.blank?
      
      trade_type = is_wx_browser ? 'JSAPI' : 'MWEB'
      openid = ''
      if is_wx_browser
        openid = order.wx_auth_profile.try(:openid) || ''
      end
      
      total_fee = SiteConfig.wx_pay_debug == 'true' ? '1' : "#{order.money}"
      params = {
        appid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        device_info: 'WEB',
        nonce_str: SecureRandom.hex(16),
        body: "账号充值",
        out_trade_no: order.uniq_id,
        total_fee: total_fee,
        spbill_create_ip: ip,
        notify_url: SiteConfig.wx_pay_notify_url,
        trade_type: trade_type,#, # JSAPI 表示微信公众号支付 # MWEB 表示微信H5支付
        openid: openid,
        attach: '支付订单'
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      result = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      # puts pay_result
      
      #####################################################
      # 此结果是微信H5支付返回的结果
      # {"return_code"=>"SUCCESS", "return_msg"=>"OK", "appid"=>"wxb0463c984a911d20", "mch_id"=>"1482457452", "device_info"=>"WEB", "nonce_str"=>"aawIACsVCELxKK9Y", "sign"=>"DE2789A6040732DE1B7551277B4840ED", "result_code"=>"SUCCESS", "prepay_id"=>"wx31213745522221cfe8f701d40376561980", "trade_type"=>"MWEB", "mweb_url"=>"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx31213745522221cfe8f701d40376561980&package=1359601095"}
      #####################################################
      
      return pay_result
    end
    
    # 发现金红包
    def self.send_redbag(billno, send_name, to_user, money, wishing, act_name, remark, scene_id)
      return if billno.blank? or send_name.blank? or to_user.blank? or money.blank?
      
      # puts '真正开始发现金红包...'
      
      # puts act_name
      # puts scene_id
      
      # debug_openid = 'oMc3D0qrLikBmC0NB9unmECSx4bU'
      
      params = {
        wxappid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        mch_billno: billno,
        nonce_str: SecureRandom.hex(16),
        send_name: send_name,
        re_openid: to_user,
        total_amount: (money * 100).to_i,
        total_num: 1,
        wishing: wishing,
        client_ip: "#{SiteConfig.server_ip}",
        act_name: act_name,
        remark: remark,
        scene_id: scene_id || 'PRODUCT_4'
      }
      
      # puts params
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      
      result = RestClient::Resource.new(
        'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack',
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("#{SiteConfig.wx_ssl_cert_file}")),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("#{SiteConfig.wx_ssl_key_file}"), "#{SiteConfig.wx_ssl_key_pass}"),
        :ssl_ca_file      =>  "#{SiteConfig.wx_ssl_ca_cert_file}",
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
      ).post(xml,  { :content_type => :xml })
      # result = RestClient.post 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      
      # puts pay_result
      
      return pay_result
      
    end
    
    # 企业付款到用户零钱
    def self.pay(billno, openid, user_name, money)
      check_name = user_name.blank? ? 'NO_CHECK' : 'FORCE_CHECK'
      re_user_name = user_name || ''
      params = {
        mch_appid: SiteConfig.wx_app_id,
        mchid: SiteConfig.wx_mch_id,
        nonce_str: SecureRandom.hex(16),
        partner_trade_no: billno,
        openid: openid,
        check_name: check_name,
        re_user_name: re_user_name,
        amount: money.to_i,
        desc: '用户提现',
        spbill_create_ip: "#{SiteConfig.server_ip}"
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      
      result = RestClient::Resource.new(
        'https://api.mch.weixin.qq.com/mmpaymkttransfers/promotion/transfers',
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("#{SiteConfig.wx_ssl_cert_file}")),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("#{SiteConfig.wx_ssl_key_file}"), "#{SiteConfig.wx_ssl_key_pass}"),
        :ssl_ca_file      =>  "#{SiteConfig.wx_ssl_ca_cert_file}",
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
      ).post(xml,  { :content_type => :xml })
      # result = RestClient.post 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      
      puts pay_result
      
      return pay_result
    end
    
    
    # 关闭订单
    def self.close_order(order)
      return false if order.blank?
      
      params = {
        appid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        out_trade_no: order.uniq_id,
        nonce_str: SecureRandom.hex(16),
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      RestClient.post 'https://api.mch.weixin.qq.com/pay/closeorder', xml, { :content_type => :xml }
      
    end
    
    # 参数签名
    def self.sign_params(params)
      arr = params.sort
      hash = Hash[*arr.flatten]
      string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('&')
      string = string + '&key=' + SiteConfig.wx_pay_api_key
      Digest::MD5.hexdigest(string).upcase
    end
    
    # 通知校验
    def self.notify_verify?(params)
      
      return false if params['appid'] != SiteConfig.wx_app_id
      return false if params['mch_id'] != SiteConfig.wx_mch_id
      
      sign = params['sign']
      params.delete('sign')
      return sign_params(params) == sign      
      
    end
    
    # 生成H5微信支付参数
    def self.generate_jsapi_params(prepay_id)
      params = {
        appId: SiteConfig.wx_app_id,
        timeStamp: Time.now.to_i,
        nonceStr: SecureRandom.hex(16),
        package: "prepay_id=#{prepay_id}",
        signType: "MD5",
      }
      
      sign = sign_params(params)
      params[:paySign] = sign
      params
    end
    
  end
end