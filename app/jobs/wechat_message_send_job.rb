class WechatMessageSendJob < ActiveJob::Base
  queue_as :messages

  def perform(to, tpl, url = '', data = {})
    user = User.find_by(id: to)
    if user.blank?
      wp = WechatProfile.find_by(id: to)
      openid = wp.openid
    else
      openid = user.wechat_profile.try(:openid)
    end
    if openid.present?
      Wechat::Message.send(openid, tpl, url, data)
    end
  end
  
end
