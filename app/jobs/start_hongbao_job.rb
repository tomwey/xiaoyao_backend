class StartHongbaoJob < ActiveJob::Base
  queue_as :scheduled_jobs
  
  def perform(event_id)
    event = Event.find_by(id: event_id)
    if event
      event.in_progress
    end
  end
end