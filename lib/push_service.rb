require 'jpush'

class PushService
  def self.push_to(msg = '', receipts = [], extras_data = {})
    MessageSendJob.perform_later(msg, receipts, extras_data)
  end
  
  def self.push(msg = '', receipts = [], extras_data = {})
    client = JPush::Client.new(SiteConfig.jpush_app_key, SiteConfig.jpush_master_secret)
    
    logger = Logger.new(STDOUT)
    
    # 设置接收者
    audience = receipts.empty? ? 'all' : JPush::Push::Audience.new.set_alias(receipts)
    
    # 封装通知对象
    notification = JPush::Push::Notification.new.
      #set_alert('test').
      set_android(
        alert: msg,
        extras: extras_data
      ).set_ios(
        alert: msg,
        sound: 'default',
        category: 'ios8 category',
        extras: extras_data
      )
      
    # 设置通知内容体
    push_payload = JPush::Push::PushPayload.new(
      platform: ['android', 'ios'],
      audience: audience,
      notification: notification,
      message: nil
    )
    
    pusher = client.pusher
    
    pusher.push(push_payload)
  end
  
end