class MessageSendJob < ActiveJob::Base
  queue_as :messages

  def perform(msg = '', to = [], extras_data = {})
    PushService.push(msg, to, extras_data)
  end
  
end
