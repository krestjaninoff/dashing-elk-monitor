require './lib/elk_monitor.rb'
require './lib/err_consul.rb'
require './lib/err_local_file.rb'

#
# Configuration
#
ELK_HOST = ENV['ELK_HOST'] || 'elastic-host'
ELK_PORT = ENV['ELK_PORT'] || '9200'
ELK_TYPE = ENV['ELK_TYPE'] || 'default'
ELK_LOG_ACTUAL_TIME = ENV['ELK_LOG_ACTUAL_TIME'] || '60m'

DEM_ERRORS_SOURCE = ENV['DEM_ERRORS_SOURCE'] || 'file'

CONSUL_KV_API = ENV['CONSUL_KV_API'] || 'http://consul-host/v1/kv'
CONSUL_DC = ENV['CONSUL_DC'] || 'dc1'
CONSUL_ERRORS_PATH = ENV['CONSUL_ERRORS_PATH'] || 'path/to/errors'

puts "Configuration: %s, %s, %s, %s, %s, %s, %s, %s" %
 [ELK_HOST, ELK_PORT, ELK_TYPE, ELK_LOG_ACTUAL_TIME, DEM_ERRORS_SOURCE, CONSUL_KV_API, CONSUL_DC, CONSUL_ERRORS_PATH]

services = []
File.read("dashboards/dashboard.erb").each_line do |line|
  next if !(line.include? "data-service")

  service = line.scan(/data-service="([^"]*)"/).last.first
  services.push service
end

err_provider = nil
if DEM_ERRORS_SOURCE.downcase == 'consul'
  err_provider = Err::Consul.new(CONSUL_KV_API, CONSUL_ERRORS_PATH, CONSUL_DC)
else
  err_provider = Err::LocalFile.new
end

monitor = Elk::Monitor.new(ELK_HOST, services, err_provider, ELK_LOG_ACTUAL_TIME, ELK_PORT, ELK_TYPE)

#
# Job scheduler
#
SCHEDULER.every '60s', :first_in => 0 do |job|
  begin
    reports = monitor.check

    if reports
      reports.each do |service, report|
        send_event("service-" + service, state: report["state"], topic: report["topic"], details: report["details"])
        puts "Message sent: " + "service-" + service + " / " + report["state"] +
          " (" + report["exec_time"].to_s + " sec): " + (report["topic"] || "ok")
      end
    end

  rescue Exception => e
    puts "\e[33mService monitor job has raised an error! Please check jobs/monitor.rb file.\e[0m"

    puts e.message
    puts e.backtrace.inspect

    services.each do |service|
      send_event("service-" + service, state: "unknown", topic: nil, details: nil)
      puts "Message sent: " + "service-" + service + " / unknown"
    end
  end

  $stdout.flush
end
