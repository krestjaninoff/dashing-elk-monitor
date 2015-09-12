#!/usr/bin/env ruby
require 'date'
require 'docker'

# Set up Docker connection
Docker.url = 'unix:///var/run/docker.sock'
Docker.validate_version!

#
# Awesome Docker monitor
#
# Based on https://github.com/swipely/docker-api
#
class DockerMonitor

  # Container states
  GREEN = "green"
  YELLOW = "yellow"
  RED = "red"

  # Dummy constructor
  def initialize(containers = [], actual_time = 15 * 60)
    @containers_to_check = containers
    @actual_time = actual_time
  end

  # Main check
  def check
    report = Hash.new
    containers_checked = []

    # Get the list of available containers
    containers = Docker::Container.all(:all => true)
    containers.each do |c|

      # Filter by container's name
      name = c.json["Name"].gsub(/^\//, "")
      containers_checked.push(name)

      next if @containers_to_check.empty? || !(@containers_to_check.include? name)

      # Gather necessary info
      running_time = self.seconds_from_now(c.json["State"]["StartedAt"])
      log_data = self.check_log_messages(c, @actual_time)

      # Determine the state of the container
      state = GREEN
      message = nil

      if !c.json["State"]["Running"]
        state = "red"
        message = "Container is down"

      elsif running_time < @actual_time
        state = YELLOW
        message = "Container recently rebooted"

      elsif !log_data.nil?
        state = RED
        message = !log_data["error"].nil? ? log_data["error"] : log_data["warn"]
      end

      report[name] = {"state" => state, "message" => message}
    end

    # Add info for missed containers
    missed_containers = @containers_to_check - containers_checked
    missed_containers.each do |c|
      report[c] = {"state" => RED, "message" => "Container not found"}
    end

    return report
  end

  # Convert string date into an amount of seconds from now
  def seconds_from_now(date_str)
    date = DateTime.parse(date_str)
    seconds = ((DateTime.now.new_offset(0) - date.new_offset(0)) * 24 * 60 * 60).to_i

    return seconds
  end

  # Check if container's logs have errors
  def check_log_messages(container, actual_time)

    last_warn = nil
    last_error = nil

    # Get container's logs string by string
    container.logs(stdout: true, stderr: true, timestamps: true, tail: 10).each_line do |l|

      log_time = DateTime.parse(l.split(/\s/)[0].gsub(/^[^2]*/, ""))
      seconds = ((DateTime.now.new_offset(0) - log_time.new_offset(0)) * 24 * 60 * 60).to_i

      # Check if a message is not too old and has an appriate logging level
      if seconds < actual_time
        if l.include? " WARN "
          last_warn = l.gsub(/^[^\]]*\]\s/, "")
        end
        if l.include? " ERROR "
          last_error = l.gsub(/^[^\]]*\]\s/, "")
        end
      end

    end

    # Gather the results
    log_data = nil
    if !last_warn.nil? || !last_error.nil?
      log_data = Hash.new
      log_data["warn"] = last_warn
      log_data["error"] = last_error
    end

    return log_data
  end

end


# Entry point for testing the script
if __FILE__ == $0
  monitor = DockerMonitor.new(["good-container", "bad-container", "missed-container"])
  puts monitor.check
end
