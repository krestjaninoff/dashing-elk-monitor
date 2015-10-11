require './lib/elk_monitor.rb'
require './lib/err_consul.rb'

#
# Configuration
#
ELK_HOST = ENV['ELK_HOST'] || 'elastic-host'
ELK_PORT = ENV['ELK_PORT'] || '9200'
LOG_ACTUAL_TIME = ENV['LOG_ACTUAL_TIME'] || '60m'

CONSUL_KV_API = ENV['CONSUL_KV_API'] || 'http://consul-host/v1/kv'
CONSUL_DC = ENV['CONSUL_DC'] || 'dc1'
CONSUL_ERRORS_PATH = ENV['CONSUL_ERRORS_PATH'] || 'path/to/errors'

containers = []
File.read("dashboards/dashboard.erb").each_line do |line|
  next if !(line.include? "data-container")

  container = line.scan(/data-container="([^"]*)"/).last.first
  containers.push container
end

err_provider = Err::Consul.new(CONSUL_KV_API, CONSUL_ERRORS_PATH, CONSUL_DC)
monitor = Elk::Monitor.new(ELK_HOST, containers, err_provider, LOG_ACTUAL_TIME, ELK_PORT)

#
# Job scheduler
#
SCHEDULER.every '60s', :first_in => 0 do |job|
  begin
    reports = monitor.check

    if reports
      reports.each do |container, report|
        send_event("docker-" + container, state: report["state"], message: report["message"], info: report["info"])
        puts "Message sent: " + "docker-" + container + " / " + report["state"] +
          " (" + report["exec_time"].to_s + " sec): " + (report["message"] || "ok")
      end
    end

  rescue Exception => e
    puts "\e[33mDocker monitor job has raised an error! Please check jobs/docker.rb file.\e[0m"

    puts e.message
    puts e.backtrace.inspect

    containers.each do |container|
      send_event("docker-" + container, state: "unknown", message: nil, info: nil)
    end
  end

  $stdout.flush
end
