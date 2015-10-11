#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'base64'

module Consul

  class Client
    def initialize(api_url, path, dc)
      @api_url = api_url.chomp('/')
      @path = path.chomp('/')
      @dc = dc
    end

    def get_known_errors
      url = URI.parse(@api_url)

      req = Net::HTTP::Get.new(url.to_s + "/" + @path + "/?keys&dc=" + @dc)
      res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}

      keys = JSON.parse(res.body).select{|k| !(k.end_with? "/")}

      errors = []
      keys.each do |k|
        req = Net::HTTP::Get.new(url.to_s + "/" + k + "?dc=" + @dc)
        res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}

        value = JSON.parse(res.body)[0]["Value"]
        errors.push Base64.decode64(value)
      end

      return errors
    end
  end
end

# Entry point for testing the script
if __FILE__ == $0
  client = Consul::Client.new("http://demo.consul.io/v1/kv", "errors", "sfo1")
  errors = client.get_known_errors

  puts errors
end
