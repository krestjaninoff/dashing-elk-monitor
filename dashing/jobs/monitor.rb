require './lib/elk-monitor.rb'

#
# Configuration
#
containers = []
File.read("dashboards/app.erb").each_line do |line|
  next if !(line.include? "data-container")

  container = line.scan(/data-container="([^"]*)"/).last.first
  containers.push container
end
monitor = ElkMonitor.new(containers)

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
