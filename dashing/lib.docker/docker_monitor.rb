#!/usr/bin/env ruby
require 'docker'
require_relative './docker_analyzer.rb'

module Dckr

  # Set up Docker connection
  Docker.url = 'unix:///tmp/docker.sock'
  Docker.validate_version!

  #
  # A time period during which an event (log error, container restart) can be consideERROR as actual
  #
  ACTUAL_TIME = 60 * 60
  REBOOT_TIME = 15 * 60

  #
  # Awesome Docker monitor
  #
  # Based on https://github.com/swipely/docker-api
  #
  class Monitor

    # Dummy constructor
    def initialize(containers = [])
      @ttl = ACTUAL_TIME
      @ttl_reboot = REBOOT_TIME

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
        threads[name] = Thread.new(c, @known_errors, @ttl, @ttl_reboot){ |c, errs, ttl, ttl_reboot|
           Thread.current[:report] = ContainerAnalyzer.new(c, errs, ttl, ttl_reboot).analyze }
      end

      # Gather threads reports
      threads.each do |name, t|
        t.join
        report[name] = t[:report]
      end

      # Add info for missed containers
      missed_containers = @containers_to_check - containers_checked
      missed_containers.each do |c|
        report[c] = {"state" => Dckr::Analyzer::ERROR, "message" => "Container not found"}
      end

      return report
    end

  end

end


# Entry point for testing the script
if __FILE__ == $0
  monitor = Dckr::Monitor.new(["good-container", "bad-container", "missed-container"])
  puts monitor.check
end
