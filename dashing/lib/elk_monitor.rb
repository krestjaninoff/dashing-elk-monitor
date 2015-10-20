#!/usr/bin/env ruby
require_relative './elk_analyzer.rb'

module Elk

  #
  # Awesome ELK monitor
  #
  class Monitor

    # Dummy constructor
    def initialize(elk_host, services, errors_provider, ttl='60m', elk_port = '9200', elk_type = 'default')
      @host = elk_host
      @port = elk_port
      @type = elk_type
      @ttl = ttl

      @services_to_check = services
      puts "Services: \n---\n" + @services_to_check.join("\n") + "\n---\n"

      @errors_provider = errors_provider
      puts 'Elk::Monitor sucessfully constructed'
    end

    # Main check
    def check
      report = Hash.new

      # Get list of knonw errors
      known_errors = @errors_provider.get_known_errors

      # Get the list of available services
      threads = Hash.new
      @services_to_check.each do |c|

        # Analyze services data in parallel
        threads[c] = Thread.new(c, known_errors, @host, @port, @type, @ttl){ |c, errs, host, port, type, ttl|
           Thread.current[:report] = Elk::Analyzer.new(c, errs, host, port, type, ttl).analyze }
      end

      # Gather threads reports
      threads.each do |name, t|
        t.join
        report[name] = t[:report]
      end

      return report
    end

  end
end


# Entry point for testing the script
if __FILE__ == $0
  monitor = Elk::Monitor.new('localhost', ["good-service", "bad-service", "missed-service"], [])
  puts monitor.check
end
