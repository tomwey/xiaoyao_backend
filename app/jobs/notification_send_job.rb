class NotificationSendJob < ActiveJob::Base
  queue_as :messages

  def perform(noti_id)
    noti = Notification.find_by(id: noti_id)
    if noti.blank?
      return
    end
    
    jpush = JPush::Client.new(SiteConfig.jpush_app_key, SiteConfig.jpush_app_secret)
    
    pusher = jpush.pusher
    
    if noti.to_users.any?
      user_alias = User.where(id: noti.to_users).pluck(:private_token)
      audience = JPush::Push::Audience.new.set_alias(user_alias)
    else
      audience = 'all'
    end
    
    platform = 'all'
    
    options = {
      apns_production: noti.is_prod,
    }
    
    alert = noti.content
    badge = noti.badge || 1
    extras = { mt: noti._type, link: noti.link || '', title: noti.title }
    notification = JPush::Push::Notification.new.
      set_alert(alert).
      set_android(
        alert: alert,
        # title: title,
        extras: extras
      ).set_ios(
        alert: alert,
        badge: badge,
        extras: extras
      )
    
    push_payload = JPush::Push::PushPayload.new(
      platform: platform,
      audience: audience,
      notification: notification
    ).set_options(options)
    
    pusher.push(push_payload)
    # PushService.push(msg, to, extras_data)
  end
  
end
