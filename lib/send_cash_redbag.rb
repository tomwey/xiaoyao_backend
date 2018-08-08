class SendCashRedbag
  def self.send(user, answer, ip = nil)
    redbag_id = CommonConfig.cash_hb_id
    if redbag_id
      @redbag = Redbag.find_by(uniq_id: redbag_id)
      if @redbag.blank?
        SendCashRedbag.send_message(user, '未找到该红包')
        return
      end
      
      unless @redbag.opened
        SendCashRedbag.send_message(user, '该红包还未上架')
        return
      end
      
      if @redbag.started_at && @redbag.started_at > Time.zone.now
        SendCashRedbag.send_message(user, '该红包还未开抢')
        return
      end
      
      # 判断是否红包还有       
      if @redbag.left_money <= 0
        SendCashRedbag.send_message(user, '您下手太慢了，红包被抢完了')
        return
      end
      
      # 检查用户是否已经抢过
      if user.grabed?(@redbag)
        SendCashRedbag.send_message(user, '您已经抢过该红包，不能重复参与')
        return
      end
      
      # 验证红包规则
      ruleable = @redbag.ruleable
      if ruleable
        if ruleable.answer != answer
            # 答案不正确，也记录日志，用户不管对错，只有一次答题的机会
          RedbagEarnLog.create!(user_id: user.id, redbag_id: @redbag.id, money: 0.0, ip: ip, location: nil)
          SendCashRedbag.send_message(user, '答案不正确')
          
          return 
        end
      end
      
      # 发红包
      money = @redbag.random_money
      if money <= 0.0
        SendCashRedbag.send_message(user, '您下手太慢了，红包被抢完了')
        return
      end
      
      # 发红包，记录日志
      RedbagEarnLog.create!(user_id: user.id, redbag_id: @redbag.id, money: money, ip: ip, location: nil)
      
      SendCashRedbag.send_message(user, '恭喜您答题成功！红包正在路上，请稍等...')
    end
  end
  
  def self.send_message(user, msg)
    payload = {
      first: {
        value: "#{msg}\n",
        color: "#FF3030",
      },
      keyword1: {
        value: "小惠",
        color: "#173177",
      },
      keyword2: {
        value: "#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}",
        color: "#173177",
      },
      remark: {
        value: "感谢使用小优大惠平台！",
        color: "#173177",
      }
    }.to_json
    
    Message.create!(message_template_id: 10, content: payload, link: '', to_users: [user.id])
  end
end