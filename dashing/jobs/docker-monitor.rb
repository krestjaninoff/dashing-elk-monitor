require './lib/docker-api-client.rb'


### Configuration
containers = ["corps-profiles-api", "corps-organizations-api", "corps-contractors-api",
  "corps-payments-api", "corps-accounts-api", "corps-catalogs-api"]
monitor = DockerMonitor.new(containers)

SCHEDULER.every '60s', :first_in => 0 do |job|
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

    puts e.message
    puts e.backtrace.inspect

    containers.each do |container|
      send_event("docker-" + container, state: "unknown", message: nil)
    end
  end
end
