#!/usr/bin/env ruby
require_relative './elk_analyzer.rb'

module Elk

  #
  # Settings
  #
  ELK_HOST = ENV['ELK_HOST'] || 'manlog1'
  ELK_PORT = ENV['ELK_PORT'] || '9200'
  LOG_ACTUAL_TIME = ENV['LOG_ACTUAL_TIME'] || '60m'


  #
  # Awesome ELK monitor
  #
  class Monitor

    # Dummy constructor
    def initialize(containers = [])
      @host = ELK_HOST
      @port = ELK_PORT
      @ttl = LOG_ACTUAL_TIME

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

      # Get the list of available containers
      threads = Hash.new
      @containers_to_check.each do |c|

        # Analyze containers data in parallel
        threads[c] = Thread.new(c, @known_errors, @host, @port, @ttl){ |c, errs, host, port, ttl|
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
  monitor = Elk::Monitor.new(["good-container", "bad-container", "missed-container"])
  puts monitor.check
end
