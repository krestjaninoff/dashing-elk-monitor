#!/usr/bin/env ruby
require_relative './elk_analyzer.rb'

module Elk

  #
  # Awesome ELK monitor
  #
  class Monitor

    # Dummy constructor
    def initialize(elk_host, containers, errors_provider, ttl='60m', elk_port = '9200')
      @host = elk_host
      @port = elk_port
      @ttl = ttl

      @containers_to_check = containers
      puts "Containers: \n---\n" + @containers_to_check.join("\n") + "\n---\n"

      @errors_provider = errors_provider
      puts 'Elk::Monitor sucessfully constructed'
    end

    # Main check
    def check
      report = Hash.new

      # Get list of knonw errors
      known_errors = @errors_provider.get_known_errors

      # Get the list of available containers
      threads = Hash.new
      @containers_to_check.each do |c|

        # Analyze containers data in parallel
        threads[c] = Thread.new(c, known_errors, @host, @port, @ttl){ |c, errs, host, port, ttl|
           Thread.current[:report] = Elk::Analyzer.new(c, errs, host, port, ttl).analyze }
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
  monitor = Elk::Monitor.new(''["good-container", "bad-container", "missed-container"], [])
  puts monitor.check
end
