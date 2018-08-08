class RedPacketService
  def self.fetchRandomMoney(hb)
    remain_size = hb.quantity - hb.open_count
    remain_money = hb.money - hb.open_money
    
    if remain_size == 0
      return 0
    end
    
    if remain_size == 1
      return remain_money
    end
    
    min = 0.01
    max = remain_money / remain_size * 2
    money = SecureRandom.random_number * max
    money = money < min ? min : money
    money = ((money * 100).floor) / 100.0
    money
  end
  
  def self.getMoney(hb)
    if hb._type == 1
      return hb.money / hb.quantity
    end
    
    return fetchRandomMoney(hb)
  end
end