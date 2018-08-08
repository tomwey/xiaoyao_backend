module Weixin
  # 微信内部路由规则类，用于简化配置
  class Router
    # 支持一下形式
    # Weixin::Router.new(type: "text")
    # Weixin::Router.new(type: "text", content: "Hello2BusUser")
    # Weixin::Router.new(type: "text", content: /^@/)
    # Weixin::Router.new { |xml| xml[:MsgType] == 'image' }
    # Weixin::Router.new (type: "text") { |xml| xml[:Content].starts_with? "@" }
    def initialize(options, &block)
      @type = options[:type] if options[:type]
      @content = options[:content] if options[:content]
      @constraint = block if block_given?
    end
    
    def matches?(request)
      xml = request.params[:xml]
      if xml.blank?
        return false
      end
      result = true
      result = result && (xml[:MsgType] == @type) if @type
      result = result && (xml[:Content] =~ @content) if @content.is_a? Regexp
      result = result && (xml[:Content] == @content) if @content.is_a? String
      result = result && @constraint.call(xml) if @constraint
      
      result
    end
    
  end
  
  module ActionController
    # 辅助方法，用于简化操作, 将xml数据封装成对象
    def weixin_xml
      # puts '----------------------------'
      # puts params[:xml]
      # puts params[:xml]
      
      hash = params[:xml]
      
      # 上报用户位置
      if hash[:Event] == 'LOCATION'
        profile = WechatProfile.find_by(openid: hash[:FromUserName])
        if profile && profile.user
          lat = hash[:Latitude]
          lng = hash[:Longitude]
          precision = hash[:Precision]
          if lat && lng
            profile.user.add_user_location(lat, lng, precision)
          end
        end
      end
      # 
      # if hash[:Event] == 'subscribe' or hash[:Event] == 'SCAN'
      #   # 初次关注注册用户
      #   profile = WechatProfile.find_by(openid: hash[:FromUserName])
      #   if profile.blank?
      #     profile = WechatProfile.new(openid: hash[:FromUserName])
      #     user = User.new
      #     user.wechat_profile = profile
      #     user.save!
      #   end
      #   
      # end # end 关注注册
      
      @weixin_xml ||= WeixinXml.new(params[:xml])
      @weixin_xml
    end
    
    class WeixinXml
      attr_accessor :content, :type, :from_user, :to_user, :pic_url, :event, :event_key
      def initialize(hash)
        @content   = hash[:Content]
        @type      = hash[:MsgType]
        @from_user = hash[:FromUserName]
        @to_user   = hash[:ToUserName]
        @pic_url   = hash[:PicUrl]
        @event     = hash[:Event]
        @event_key = hash[:EventKey]
      end
    end
  end
end

ActionController::Base.class_eval do
  include ::Weixin::ActionController
end
ActionView::Base.class_eval do
  include ::Weixin::ActionController
end