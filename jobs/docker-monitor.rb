require './lib/docker-api-client.rb'


### Configuration
monitor = DockerMonitor.new(["ghost-local", "missed-container"])

SCHEDULER.every '10s', :first_in => 0 do |job|
  begin
    reports = monitor.check

    if reports
      reports.each do |container, report|
        send_event("docker-" + container, state: report["state"], message: report["message"])
        puts "Message sent: " + "docker-" + container + " / " + report["state"]
      end
    end

  rescue Exception => e
    puts "\e[33mDocker monitor job has raised an error! Please check jobs/docker.rb file.\e[0m"
    puts e.backtrace.inspect
  end
end
