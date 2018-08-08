class CancelTaskJob < ActiveJob::Base
  queue_as :scheduled_jobs
  
  def perform(id, st)
    
    if st == 1
      obj = StudioGrabTask.find_by(id: id)
    else
      obj = nil
    end
    
    if obj and obj.pending?
      obj.expire
    end
    
    # @order = Order.find_by(id: order_id)
    # if @order and @order.pending?
    #   @order.cancel
    #   # 发送取消通知消息
    #   @order.send_order_state_msg('系统取消了您的订单', '已取消', '30分钟内未支付，系统自动取消订单')
    #
    # end
  end
end