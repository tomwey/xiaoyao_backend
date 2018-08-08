require 'rest-client'
module Wechat
  class Message
        
    def self.send(to, tpl, url = '', data = {})

      return if to.blank? or tpl.blank? or data.blank?

      # 发送模板消息
      post_url  = "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=#{Wechat::Base.fetch_access_token}"
      post_body = {
         touser: to,
         template_id: tpl,
         url: url,         
         data: data,
      }.to_json
      
      # puts post_body
      RestClient.post post_url, post_body, :content_type => :json, :accept => :json
    end
    
    def self.parse_data(first, values = [], remark = '')
      data = {}
      data[:first] = {
        value: first,
        color: '#173177'
      }
      
      values.each do |item|
        item.each do |key, value|
          data[key.to_sym] = {
            value: value,
            color: '#173177'
          }
        end
      end
      
      data[:remark] = {
        value: remark,
        color: '#173177'
      }
      
      data
    end
    
  end
end