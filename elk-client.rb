#!/usr/bin/env ruby

require 'net/http'
require 'json'

@container = "app-name"
@ttl = "60m"

@post_ws = "/logstash-2015.10.10/log-type/_search"
@query = <<-EOS
{
  "filter" : {
            "and" : [
                { "term" : { "app_id.raw" : "#{@container}" } },
                { "or" : [
                  { "term" : { "level.raw" : "ERROR" } },
                  { "term" : { "level.raw" : "WARN" } }
                ]},
                {"range" : { "@timestamp" : { "gte": "now-#{@ttl}" } } }
              ]
            }
  },
  "sort" : [ {
    "@timestamp" : {
      "order" : "desc"
    }
  } ],
  "size" : 1
}
EOS

puts @query

req = Net::HTTP::Post.new(@post_ws, initheader = {'Content-Type' =>'application/json'})
req.body = @query

response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
hits = JSON.parse(response.body)['hits']
error = hits['hits'][0]

puts error['_source']['logger_name']
puts error['_source']['message']
