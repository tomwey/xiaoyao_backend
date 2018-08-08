# This file is used by Rack-based servers to start the application.

# require 'unicorn/oob_gc'
# require 'unicorn/worker_killer'
#
# use Unicorn::OobGC, 10
#
# use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
#
# use Unicorn::WorkerKiller::Oom, (192*(1024**2)), (256*(1024**2))

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

memory_usage = (`ps -o rss= -p #{$PID}`.to_i / 1024.00).round(2)
puts "=> Memory usage: #{memory_usage} MB"
