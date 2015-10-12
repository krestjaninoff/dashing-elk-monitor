#!/usr/bin/env ruby
require 'date'
require 'net/http'
require 'json'

module Elk

  #
  # Awesome ELK service analyzer
  #
  class Analyzer

    # service states
    UNKNOWN = "unknown"
    OK = "ok"
    WARN = "warn"
    ERROR = "error"

    def initialize(service, known_errors, host, port, ttl)
      @service = service
      @known_errors = known_errors

      @host = host
      @port = port
      @ttl = ttl
    end

    def analyze
      start_time = Time.now.to_i

      begin
        state, topic, details = self.check_log_messages(@service, @ttl)

      rescue Exception => e
        state = UNKNOWN
        topic = 'Internal error :('
        details = e.message

        puts e.message
        puts e.backtrace.inspect
      end

      exec_time = Time.now.to_i - start_time
      return {"state" => state, "topic" => topic, "details" => details, "exec_time" => exec_time}
    end

    # Check if service's logs have errors
    def check_log_messages(service, ttl)
      log_data = nil

      # Get service's logs string by string
      begin
        logs = get_elk_data(build_logs_query(service, @known_errors, ttl))

        if logs.nil?
          log_data = [UNKNOWN, "Monitoring error", nil]

        elsif logs['total'] > 0

          log_entry = logs['hits'][0]
          log_entry['logger_name'] = log_entry['_source']['logger_name'].split(".").last
          log_entry['message'] = log_entry['_source']['message'][0, 256]

          if log_entry['_source']['level'] == 'WARN'
            log_data = [WARN, log_entry['logger_name'], log_entry['message']]

          else
            log_data = [ERROR, log_entry['logger_name'], log_entry['message']]
          end

        else
          logs = get_elk_data(build_alive_query(service, ttl))

          if logs['total'] > 0
            log_data = [OK, "OK", nil]
          else
            log_data = [UNKNOWN, "No logs from App", nil]
          end
        end

      # Handle errors
      rescue Exception => e
        log_data = [UNKNOWN, "ES unavailable :(", e.message]

        puts e.message
        puts e.backtrace.inspect
      end

      return log_data[0], log_data[1], log_data[2]
    end

    def build_logs_query(service, known_errors, ttl)

      # prepare a part with known errors filter
      known_errors_query = ''
      if !known_errors.empty?

        known_errors.each do |e|
          known_errors_query += %q["must_not" : { "query_string": { "default_field" : "message", "minimum_should_match": "100%", "query": "] + e + %q[" } },]
        end
        known_errors_query = known_errors_query.chomp(',')

        known_errors_query = %q["query" : { "bool" : {] + known_errors_query + %q[} },]
      end

      # build the query
      query = <<-EOS
        {
          #{known_errors_query}
          "filter" : {
              "and" : [
                  { "term" : { "app_id.raw" : "#{service}" } },
                  { "or" : [
                    { "term" : { "level.raw" : "ERROR" } },
                    { "term" : { "level.raw" : "WARN" } }
                  ]},
                  { "range" : { "@timestamp" : { "gte": "now-#{ttl}" } } }
              ]
          },
          "sort" : [
            { "level_value" : { "order" : "desc"  } }
          ],
          "size" : 1
        }
        EOS

      return query
    end

    def build_alive_query(service, ttl)
      query = <<-EOS
        {
          "filter" : {
              "and" : [
                  { "term" : { "app_id.raw" : "#{service}" } },
                  { "range" : { "@timestamp" : { "gte": "now-#{ttl}" } } }
              ]
          },
          "size" : 1
        }
        EOS

      return query
    end

    # Check if service's logs have errors
    def get_elk_data(query)
      index = "logstash-" + Time.now.strftime("%Y.%m.%d")
      url = "/#{index}/rest-api/_search"

      req = Net::HTTP::Post.new( url, initheader = {'Content-Type' =>'application/json'} )
      req.body = query

      response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
      hits = JSON.parse(response.body)['hits']

      if hits.nil?
        puts response.body
      end

      return hits
    end

  end

end
