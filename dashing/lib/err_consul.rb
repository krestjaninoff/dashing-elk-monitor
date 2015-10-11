#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'base64'

module Err

  #
  # Awesome way to store your known errors in Consul
  #
  # Hint, jira issues numbers can be used as keys!
  # Hint 2, you can use Consul UI to manage your errors!
  #
  class Consul
    def initialize(api_url, path, dc)
      @api_url = api_url.chomp('/')
      @path = path.chomp('/')
      @dc = dc

      @known_errors_curr = []

      puts 'Err::Consul sucessfully constructed'
    end

    def get_known_errors
      url = URI.parse(@api_url)

      request = Net::HTTP::Get.new(url.to_s + "/" + @path + "/?keys&dc=" + @dc)
      response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}

      if !response.kind_of? Net::HTTPSuccess
        puts "Consul failed request: " + request.path
        raise "Consul says No :("
      end

      keys = JSON.parse(response.body).select{|k| !(k.end_with? "/")}

      known_errors = []
      keys.each do |k|

        request = Net::HTTP::Get.new(url.to_s + "/" + k + "?dc=" + @dc)
        response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
        if !response.kind_of? Net::HTTPSuccess
          puts "Consul failed request: " + request.path
          raise "Consul says No :("
        end

        value = JSON.parse(response.body)[0]["Value"]
        known_errors.push Base64.decode64(value)
      end

      if @known_errors_curr != known_errors
        puts "Known errors: \n---\n" + known_errors.join("\n") + "\n---\n"
      end
      @known_errors_curr = known_errors

      return known_errors
    end

  end
end

# Entry point for testing the script
if __FILE__ == $0
  client = Err::Consul.new("http://demo.consul.io/v1/kv", "errors", "sfo1")
  errors = client.get_known_errors
end
