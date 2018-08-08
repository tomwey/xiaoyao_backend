module Wechat
  class Sign
    def self.sign(url, noncestr, timestamp)
      jsapi_ticket = Wechat::Base.fetch_jsapi_ticket
      # puts jsapi_ticket
      string = "jsapi_ticket=#{jsapi_ticket}&noncestr=#{noncestr}&timestamp=#{timestamp}&url=#{url}"
      Digest::SHA1.hexdigest(string)
    end
    
    def self.sign_package(url)
      timestamp = Time.now.to_i
      random_str = SecureRandom.hex(4)
      signature  = Wechat::Sign.sign(url, random_str, timestamp)
      {
          debug: SiteConfig.wx_config_debug == 'true',
          appId: SiteConfig.wx_app_id,
          timestamp: timestamp,
          nonceStr: random_str,
          signature: signature,
          jsApiList: ['chooseWXPay']
      }
    end
    
  end
end

# ['chooseWXPay','onMenuShareTimeline', 'onMenuShareAppMessage', 'onMenuShareQQ', 'onMenuShareQZone','openLocation','getLocation','getNetworkType']