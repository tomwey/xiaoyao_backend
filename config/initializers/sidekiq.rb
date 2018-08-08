Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 5 # 每隔5秒取一次任务
end