class WithdrawJob < ActiveJob::Base
  queue_as :scheduled_jobs
  
  def perform(id)
    withdraw = Withdraw.find_by(id: id)
    if withdraw
      withdraw.do_pay
    end
  end
  
end