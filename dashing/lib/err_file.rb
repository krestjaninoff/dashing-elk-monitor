#!/usr/bin/env ruby

module Err
  class File

    def initialize
      @known_errors_curr = []
    end

    def get_known_errors
      known_errors = []

      begin
        File.read("../known.errors").each_line do |line|
          error = line.tr("\n","")
          known_errors.push error if !error.empty?
        end

        if @known_errors_curr != known_errors
          puts "Known errors: \n---\n" + known_errors.join("\n") + "\n---\n"
        end
        @known_errors_curr = known_errors

      rescue Exception => e
        puts "Registry with known errors not found"
      end

      return known_errors
    end

  end
end
