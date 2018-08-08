class CashRedbagSendJob < ActiveJob::Base
  queue_as :scheduled_jobs

  def perform(log_id)
    
    cash_hb_log = CashRedbagSendLog.find_by(id: log_id)
    # puts cash_hb_log
    return if cash_hb_log.blank?
    
    to_user = cash_hb_log.user.wechat_profile.try(:openid)
    
    # 调用微信发红包接口
    result = Wechat::Pay.send_redbag(cash_hb_log.uniq_id, 
                                     cash_hb_log.send_name, 
                                     to_user, 
                                     cash_hb_log.money.to_f, 
                                     cash_hb_log.wishing, 
                                     cash_hb_log.act_name, 
                                     cash_hb_log.remark, 
                                     cash_hb_log.scene_id)
    if result
      if result['return_code'] == 'SUCCESS' && result['result_code'] == 'SUCCESS'
        cash_hb_log.sent_at = Time.zone.now
        cash_hb_log.sent_error = nil
      else
        cash_hb_log.sent_at = nil
        cash_hb_log.sent_error = "return_msg:#{result['return_msg']};
          err_code:#{result['err_code']};err_code_desc:#{result['err_code_des']}"
      end
      cash_hb_log.save
    end
    
  end
  
end
