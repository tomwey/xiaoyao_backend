class SendCashRedbagJob < ActiveJob::Base
  queue_as :scheduled_jobs

  def perform(log_id)
    
    cash_hb_log = CashRedbagLog.find_by(id: log_id)
    # puts cash_hb_log
    return if cash_hb_log.blank?
    
    redbag = cash_hb_log.redbag
    
    # puts redbag
    return if redbag.blank?
    # return if !redbag.is_cash_hb
    
    config = redbag.wechat_redbag_config
    # puts config
    
    return if config.blank?
    
    to_user = cash_hb_log.user.wechat_profile.try(:openid)
    
    # puts to_user
    # 调用微信发红包接口
    
    result = Wechat::Pay.send_redbag(cash_hb_log.uniq_id, 
                                     config.send_name, 
                                     to_user, 
                                     cash_hb_log.money.to_f, 
                                     config.wishing, 
                                     config.act_name, 
                                     config.remark, 
                                     config.scene_id)
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
