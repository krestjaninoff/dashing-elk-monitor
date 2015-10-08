#!/usr/bin/env ruby
require 'date'
require 'docker'

# Set up Docker connection
Docker.url = 'unix:///tmp/docker.sock'
Docker.validate_version!

#
# A time period during which an event (log error, container restart) can be considered as actual
#
ACTUAL_TIME = 60 * 60
REBOOT_TIME = 15 * 60

#
# Awesome Docker monitor
#
# Based on https://github.com/swipely/docker-api
#
class DockerMonitor

  # Dummy constructor
  def initialize(containers = [])
    @containers_to_check = containers
    puts "Containers: \n---\n" + @containers_to_check.join("\n") + "\n---\n"

    @known_errors = []
    begin
      File.read("../known.errors").each_line do |line|
        error = line.tr("\n","")
        @known_errors.push error if !error.empty?
      end
      puts "Known errors: \n---\n" + @known_errors.join("\n") + "\n---\n"
    rescue Exception => e
      puts "Registry with known errors not found"
    end
  end

  # Main check
  def check
    report = Hash.new
    containers_checked = []

    # Get the list of available containers
    threads = Hash.new
    containers = Docker::Container.all(:all => true)
    containers.each do |c|

      # Filter by container's name
      name = c.json["Name"].gsub(/^\//, "")
      containers_checked.push(name)

      next if @containers_to_check.empty? || !(@containers_to_check.include? name)

      # Analyze containers data in parallel
      threads[name] = Thread.new(c, @known_errors){ |c, errs|
         Thread.current[:report] = ContainerAnalyzer.new(c, errs).analyze }
    end

    # Gather threads reports
    threads.each do |name, t|
      t.join
      report[name] = t[:report]
    end

    # Add info for missed containers
    missed_containers = @containers_to_check - containers_checked
    missed_containers.each do |c|
      report[c] = {"state" => ContainerAnalyzer::RED, "message" => "Container not found"}
    end

    return report
  end

end

#
# Awesome docker container analyzer
#
class ContainerAnalyzer

  # Container states
  GREEN = "green"
  YELLOW = "yellow"
  RED = "red"

  def initialize(container, known_errors=[])
    @container = container
    @known_errors = known_errors
  end

  def analyze
    start_time = Time.now.to_i

    begin
      running_time = self.seconds_from_now(@container.json["State"]["StartedAt"])
      log_data = self.check_log_messages(@container, ACTUAL_TIME)

      # Determine the state of the container
      state, message = self.analyze_metrics(@container, running_time, log_data)

    rescue Exception => e
      state = RED
      message = e.message

      puts e.message
      puts e.backtrace.inspect
    end

    exec_time = Time.now.to_i - start_time
    return {"state" => state, "message" => message, "exec_time" => exec_time}
  end

  def analyze_metrics(c, running_time, log_data)
    state = GREEN
    message = nil

    if !c.json["State"]["Running"]
      state = "red"
      message = "Container is down"

    elsif !log_data.nil? && !log_data["warn"].nil?
      state = YELLOW
      message = log_data["warn"]

    elsif !log_data.nil? && !log_data["error"].nil?
      state = RED
      message = log_data["error"]

    elsif running_time < REBOOT_TIME
      state = YELLOW
      message = "Container recently rebooted"
    end

    return state, message
  end

  # Check if container's logs have errors
  def check_log_messages(container, actual_time)

    last_warn = nil
    last_error = nil
    msg_pattern = /^[^\]]*\]\s/ # everything from the beginning till the first ]

    # Get container's logs string by string
    currL = nil
    begin
      container.logs(stdout: true, stderr: true, timestamps: true, tail: 10000).each_line do |l|
        currL = l

        # Filter out the known errors
        next if (@known_errors.any? { |error| l.include? (error) })

        # A tricky way to avoid invalid symbols from Docker
        l = l.gsub(/[\x80-\xff]/, "")
        next if l.size < 30

        # Retrieve date (docker returns logs with a garbage before dates, so we have to workaround that - to be fixed)
        #log_time = DateTime.parse(l.gsub(/^.*(?=(20\d{2}-))/, "").split(/\s/)[0])
        log_time = DateTime.parse(l.gsub(/^[^2]*/, "").to_s[0, 19])
        seconds = ((DateTime.now.new_offset(0) - log_time.new_offset(0)) * 24 * 60 * 60).to_i

        # Check if the message is not too old
        if seconds < actual_time

          # Check message's loggin level
          if l.include? " WARN "
            last_warn = l.gsub(msg_pattern, "")
          elsif l.include? " ERROR "
            last_error = l.gsub(msg_pattern, "")
          end
        end

      end

    # Handle errors
    rescue Exception => e
      last_warn = "Unparsable logs"

      puts e.message
      puts currL
      puts e.backtrace.inspect
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

  # Convert string date into an amount of seconds from now
  def seconds_from_now(date_str)
    date = DateTime.parse(date_str)
    seconds = ((DateTime.now.new_offset(0) - date.new_offset(0)) * 24 * 60 * 60).to_i

    return seconds
  end

end


# Entry point for testing the script
if __FILE__ == $0
  monitor = DockerMonitor.new(["good-container", "bad-container", "missed-container"])
  puts monitor.check
end
