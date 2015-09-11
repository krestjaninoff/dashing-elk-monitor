require_relative '../lib/docker-monitor.rb'


### Configuration
monitor = DockerMonitor.new(["stupefied_ardinghelli", "missed_container"])

SCHEDULER.every '5s', :first_in => 0 do |job|
  begin
    reports = monitor.check
    
    if reports
      reports.each do |container, report|
        send_event("docker-" + container, status: report["status"], message: report["message"])
      end
    end

  rescue Twitter::Error
    puts "\e[33mDocker monitor job has raised an error! Please check jobs/docker.rb file.\e[0m"
  end
end
