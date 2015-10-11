require './lib/elk_monitor.rb'
require './lib/err_consul.rb'

#
# Configuration
#
ELK_HOST = ENV['ELK_HOST'] || 'elastic-host'
ELK_PORT = ENV['ELK_PORT'] || '9200'
LOG_ACTUAL_TIME = ENV['ELK_LOG_ACTUAL_TIME'] || '60m'

CONSUL_KV_API = ENV['CONSUL_KV_API'] || 'http://consul-host/v1/kv'
CONSUL_DC = ENV['CONSUL_DC'] || 'dc1'
CONSUL_ERRORS_PATH = ENV['CONSUL_ERRORS_PATH'] || 'path/to/errors'

services = []
File.read("dashboards/dashboard.erb").each_line do |line|
  next if !(line.include? "data-service")

  service = line.scan(/data-service="([^"]*)"/).last.first
  services.push service
end

err_provider = Err::Consul.new(CONSUL_KV_API, CONSUL_ERRORS_PATH, CONSUL_DC)
monitor = Elk::Monitor.new(ELK_HOST, services, err_provider, LOG_ACTUAL_TIME, ELK_PORT)

#
# Job scheduler
#
SCHEDULER.every '60s', :first_in => 0 do |job|
  begin
    reports = monitor.check

    if reports
      reports.each do |service, report|
        send_event("service-" + service, state: report["state"], message: report["message"], info: report["info"])
        puts "Message sent: " + "service-" + service + " / " + report["state"] +
          " (" + report["exec_time"].to_s + " sec): " + (report["message"] || "ok")
      end
    end

  rescue Exception => e
    puts "\e[33mService monitor job has raised an error! Please check jobs/monitor.rb file.\e[0m"

    puts e.message
    puts e.backtrace.inspect

    services.each do |service|
      send_event("service-" + service, state: "unknown", message: nil, info: nil)
      puts "Message sent: " + "service-" + service + " / unknown"
    end
  end

  $stdout.flush
end
