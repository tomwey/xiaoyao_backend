class Withdraw < ActiveRecord::Base
  scope :payed, -> { where.not(payed_at: nil) }
  
  before_create :generate_uniq_id
  def generate_uniq_id
    begin
      self.uniq_id = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
    end while self.class.exists?(:uniq_id => uniq_id)
  end
  
  after_create :add_trade_log
  def add_trade_log
    # TradeLog.create!(tradeable: self, user_id: self.user_id, money: self.money, title: "#{note || '提现'}#{'%.2f' % self.money}元")
    puts self.uniq_id
    
    TradeLog.create!(tradeable_type: self.class, 
                     tradeable_id: self.uniq_id,
                     user_id: self.user_id, 
                     money: -self.money, 
                     title: self.note || '提现',
                     action: 'withdraw'
                     )
    
    
    # if self.money < 10
      # 自动提现
      WithdrawJob.set(wait: 1.seconds).perform_later(self.id)
    # else
      # 发送消息
      # send_message
    # end
  end
  
  def wx_auth_profile
    @profile ||= AuthProfile.where(user_id: self.user_id, provider: 'wechat').first
  end
  
  def do_pay
    # Wechat::Pay.pay(billno, openid, user_name, money)
    if account_no == account_name
      # 微信提现
      result = Wechat::Pay.pay(self.uniq_id, wx_auth_profile.try(:openid), account_name, (money - fee))
      puts result
      if result['return_code'] == 'SUCCESS' && result['result_code'] == 'SUCCESS'
        self.payed_at = Time.zone.now#DateTime.parse(result['payment_time'])
        self.save!
        
        # 通知管理员
        # notify_backend_manager('')
        
        return ''
      else
        
        # 通知管理员
        # notify_backend_manager(result['return_msg'])
        
        return result['return_msg']
      end
    else
      code,msg = Alipay::Pay.pay(self.uniq_id, account_no, account_name, money - fee)
      if code == 0
        self.payed_at = Time.zone.now
        self.save!
        
        # 通知管理员
        # notify_backend_manager('')
        
        return ''
      else
        
        # 通知管理员
        # notify_backend_manager(msg)
        
        return msg
      end
    end
    
  end
  
end
