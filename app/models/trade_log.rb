class TradeLog < ActiveRecord::Base
  # belongs_to :tradeable
  
  before_create :generate_uniq_id
  def generate_uniq_id
    begin
      self.uniq_id = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
    end while self.class.exists?(:uniq_id => uniq_id)
  end
  
  after_create :change_user_balance_or_pay_money
  def change_user_balance_or_pay_money
    if self.tradeable_type == 'Redpack'
      if tradeable.is_cash? 
        # 现金红包直接修改余额
        balance = user.balance + self.money
        user.balance = [0, balance].max
        user.save!
      else
        # 非现金红包修改用户的抵扣余额
        if self.action == 'taked_hb' # 只有抢消费红包才修改用户的抵扣余额
          pay_money = user.pay_money + self.money
          user.pay_money = [0, pay_money].max
          user.save!
        end
      end
    else
      # 充值或提现直接操作余额
      balance = user.balance + self.money
      user.balance = [0, balance].max
      user.save!
    end
  end
  
  def tradeable
    klass = Object.const_get self.tradeable_type
    @tradeable ||= klass.find_by(uniq_id: self.tradeable_id)
  end
  
  def user
    @user ||= User.find_by(uid: self.user_id)
  end
  
end
