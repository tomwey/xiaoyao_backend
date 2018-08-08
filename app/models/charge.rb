class Charge < ActiveRecord::Base
  scope :payed, -> { where.not(payed_at: nil) }
  
  before_create :generate_uniq_id
  def generate_uniq_id
    begin
      self.uniq_id = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
    end while self.class.exists?(:uniq_id => uniq_id)
  end
  
  def not_payed?
    self.payed_at.blank?
  end
  
  def pay!
    self.payed_at = Time.zone.now
    self.save!
                         
    TradeLog.create!(tradeable_type: self.class, 
                     tradeable_id: self.uniq_id,
                     user_id: self.user_id, 
                     money: self.money, 
                     title: '充值',
                     action: 'charge'
                     )
  end
  
  def wx_auth_profile
    @profile ||= AuthProfile.where(user_id: self.user_id, provider: 'wechat').first
  end
  # def user
  #   @user ||= User.find_by(uid: self.user_id)
  # end
end
