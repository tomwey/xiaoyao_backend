require 'rest-client'
module Wechat
  class Base
    def self.fetch_access_token
      @access_token = Rails.cache.read("wechat.access_token")
      if @access_token.blank?
        resp = RestClient.get 'https://api.weixin.qq.com/cgi-bin/token', 
                       { :params => { :grant_type => "client_credential",
                                      :appid      => SiteConfig.wx_app_id,
                                      :secret     => SiteConfig.wx_app_secret 
                                    } 
                       }
                     
        result = JSON.parse(resp)

        @access_token = result['access_token']
        Rails.cache.write("wechat.access_token", @access_token, expires_in: 110.minutes)
      end
      @access_token
    end
    
    # 创建用户组
    def self.create_user_group(name)
      
      tag_id = $redis.get(name)
      
      if tag_id.present?
        return tag_id
      end
      
      params = {
        tag: {
          name: name
        }
      }
      
      post_url = "https://api.weixin.qq.com/cgi-bin/tags/create?access_token=#{Wechat::Base.fetch_access_token}"
      resp = RestClient.post post_url, params.to_json, :content_type => :json, :accept => :json
      result = JSON.parse(resp)
      if result && result["tag"]
        $redis.set(result["tag"]["name"], result["tag"]["id"])
        return result["tag"]["id"]
      else
        return nil
      end
        
    end
    
    # 添加用户到用户组
    def self.add_users_to_group(openid_list, group_id)
      return if group_id.blank?
      return if openid_list.blank? or openid_list.empty?
      
      params = {
        openid_list: openid_list,
        tagid: group_id
      }
      
      post_url = "https://api.weixin.qq.com/cgi-bin/tags/members/batchtagging?access_token=#{Wechat::Base.fetch_access_token}"
      resp = RestClient.post post_url, params.to_json, :content_type => :json, :accept => :json
      result = JSON.parse(resp)
      if result && result["errcode"] && result["errcode"].to_i == 0
        return true
      else
        return false
      end
    end
    
    # 获取用户的基本信息
    def self.fetch_user_base_info(access_token, openid)
      return nil if access_token.blank? or openid.blank?
      
      resp = RestClient.get 'https://api.weixin.qq.com/cgi-bin/user/info', 
                       { :params => { :access_token => access_token,
                                      :openid       => openid,
                                      :lang         => 'zh_CN' 
                                    } 
                       }
      result = JSON.parse(resp)
      return result
    end
    
    def self.fetch_jsapi_ticket
      @jsapi_ticket = Rails.cache.read("wechat.jsapi_ticket")
      if @jsapi_ticket.blank?
        resp = RestClient.get 'https://api.weixin.qq.com/cgi-bin/ticket/getticket', 
                       { :params => { :access_token => Wechat::Base.fetch_access_token,
                                      :type         => 'jsapi'
                                    } 
                       }
                     
        result = JSON.parse(resp)
        @jsapi_ticket = result['ticket']
        Rails.cache.write("wechat.jsapi_ticket", @jsapi_ticket, expires_in: 110.minutes)
      end
      @jsapi_ticket
    end
    
    def self.fetch_qrcode_ticket(code, limit = true)
      post_url = "https://api.weixin.qq.com/cgi-bin/qrcode/create?access_token=#{Wechat::Base.fetch_access_token}"
      # "expire_seconds": 604800, "action_name": "QR_SCENE" 
      if limit
        # @ticket = Rails.cache.read("wechat.qr_limit.ticket")
        # return @ticket unless @ticket.blank?
        
        post_data = {
          action_name: "QR_LIMIT_STR_SCENE",
          action_info: {
            scene: {
              scene_id: 518,
              scene_str: code
            }
          }
        }.to_json
      else
        post_data = {
          expire_seconds: 30 * 24 * 3600, # 30 days
          action_name: "QR_STR_SCENE",    # 1-64个长度的字符串参数
          action_info: {
            scene: {
              scene_id: 518,
              scene_str: code
            }
          }
        }.to_json
      end
      
      resp = RestClient.post post_url, post_data, :content_type => :json, :accept => :json
      result = JSON.parse(resp)
      ticket = result['ticket']
      
      # puts resp
      # 将永久二维码放到缓存中
      # Rails.cache.write('wechat.qr_limit.ticket', ticket) if limit
      # puts result
      
      ticket
    end
    
    # 创建自定义菜单
    def self.create_wechat_menu(menu_json)
      resp = RestClient.post "https://api.weixin.qq.com/cgi-bin/menu/create?access_token=#{Wechat::Base.fetch_access_token}", menu_json, :content_type => :json, :accept => :json
      puts resp
      result = JSON.parse(resp)
      if result['errcode'].to_s != '0'
        Rails.cache.write("wechat.access_token", '')
        create_wechat_menu(menu_json)
      end
    end
    
    # 检测请求是否来自微信服务器
    def self.check_wechat_legality(timestamp, nonce, signature)
      if timestamp.blank? or nonce.blank? or signature.blank?
        return false
      end
      
      array = [SiteConfig.wx_app_token, timestamp, nonce].sort
      signature == Digest::SHA1.hexdigest(array.join) 
    end
    
  end
end