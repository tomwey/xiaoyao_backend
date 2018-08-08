class CreateVipCardJob < ActiveJob::Base
  queue_as :scheduled_jobs
  
  def perform(task_id)
    
    @task = VipCardTask.find_by(id: task_id)
    
    count = [@task.quantity, 1].max
    count.times do 
      VipCard.create(month: @task.month)
    end
    
  end
end