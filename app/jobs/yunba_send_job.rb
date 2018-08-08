class YunbaSendJob < ActiveJob::Base
  queue_as :messages

  def perform(topic, content)
    Yunba.send(content, topic)
  end
  
end
