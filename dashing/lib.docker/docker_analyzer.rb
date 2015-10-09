#!/usr/bin/env ruby
require 'date'
require 'docker'

module Dckr

  #
  # Awesome docker container analyzer
  #
  class Analyzer

    # Container states
    OK = "ok"
    WARN = "warn"
    ERROR = "error"

    def initialize(container, known_errors=[], ttl, ttl_reboot)
      @container = container
      @known_errors = known_errors
      @ttl = ttl
      @ttl_reboot = ttl_reboot
    end

    def analyze
      start_time = Time.now.to_i

      begin
        running_time = self.seconds_from_now(@container.json["State"]["StartedAt"])
        log_data = self.check_log_messages(@container, ttl)

        # Determine the state of the container
        state, message = self.analyze_metrics(@container, running_time, log_data)

      rescue Exception => e
        state = ERROR
        message = e.message

        puts e.message
        puts e.backtrace.inspect
      end

      exec_time = Time.now.to_i - start_time
      return {"state" => state, "message" => message, "exec_time" => exec_time}
    end

    def analyze_metrics(c, running_time, log_data)
      state = OK
      message = nil

      if !c.json["State"]["Running"]
        state = "ERROR"
        message = "Container is down"

      elsif !log_data.nil? && !log_data["warn"].nil?
        state = WARN
        message = log_data["warn"]

      elsif !log_data.nil? && !log_data["error"].nil?
        state = ERROR
        message = log_data["error"]

      elsif running_time < @ttl_reboot
        state = WARN
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

end
