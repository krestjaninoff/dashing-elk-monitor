#!/usr/bin/env ruby
require 'date'
require 'net/http'
require 'json'

#
# Settings
#
ELK_HOST = ENV['ELK_HOST'] || 'manlog1'
ELK_PORT = ENV['ELK_PORT'] || '9200'
LOG_ACTUAL_TIME = ENV['LOG_ACTUAL_TIME'] || '60m'


#
# Awesome ELK monitor
#
class ElkMonitor

  # Dummy constructor
  def initialize(containers = [])
    @host = ELK_HOST
    @port = ELK_PORT

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
      threads[name] = Thread.new(c, @known_errors){ |c, errs|
         Thread.current[:report] = ContainerAnalyzer.new(c, errs).analyze }
    end

    # Gather threads reports
    threads.each do |name, t|
      t.join
      report[name] = t[:report]
    end

    return report
  end

end

#
# Awesome ELK container analyzer
#
class ContainerAnalyzer

  # Container states
  UNKNOWN = "unknown"
  OK = "ok"
  WARN = "warn"
  ERROR = "error"

  def initialize(container, known_errors=[])
    @container = container
    @known_errors = known_errors
  end

  def analyze
    start_time = Time.now.to_i

    begin
      state, message, details = self.check_log_messages(@container, LOG_ACTUAL_TIME)

    rescue Exception => e
      state = ERROR
      message = e.message
      details = nil

      puts e.message
      puts e.backtrace.inspect
    end

    exec_time = Time.now.to_i - start_time
    return {"state" => state, "message" => message, "details" => details, "exec_time" => exec_time}
  end

  # Check if container's logs have errors
  def check_log_messages(container, LOG_ACTUAL_TIME)
    log_data = nil

    # Get container's logs string by string
    begin
      logs = get_elk_data(build_logs_query(container, @known_errors, LOG_ACTUAL_TIME))

      if logs['total'] > 0
        log_entry = logs['hits'][0]
        log_entry['logger_name'] = log_entry['logger_name'].truncate(32)
        log_entry['message'] = log_entry['message'].truncate(256)

        if log_entry['level'] == 'WARN'
          log_data = [WARN, log_entry['logger_name'], log_entry['message']]

        else
          log_data = [ERROR, log_entry['logger_name'], log_entry['message']]
        end

      else
        logs = get_elk_data(build_alive_query(container, LOG_ACTUAL_TIME))

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

  def build_logs_query(container, known_errors, ttl)
    index = "logstash-" + Time.now.strftime("%Y.%m.%d")
    url = "/#{index}/rest-api/_search"

    known_errors_query = nil
    if !known_errors.empty?

      known_errors.each do |e|
        known_errors_query += %q["must_not" : { "match": { "message": "] + e +  %q[" } },]
      end
      known_errors_query.chomp(',')

      known_errors_query = %q["query" : { "bool" : {] + known_errors_query + %q[} },]
    end

    query = <<-EOS
      {
        #{known_errors_query}
        "filter" : {
            "and" : [
                { "term" : { "app_id.raw" : "#{container}" } },
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

  def build_alive_query(container, ttl)
    query = <<-EOS
      {
        "filter" : {
            "and" : [
                { "term" : { "app_id.raw" : "#{container}" } },
                { "range" : { "@timestamp" : { "gte": "now-#{ttl}" } } }
            ]
        },
        "size" : 1
      }
      EOS

    return query
  end

  # Check if container's logs have errors
  def get_elk_data(query)

    req = Net::HTTP::Post.new( url, initheader = {'Content-Type' =>'application/json'} )
    req.body = query

    response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
    hits = JSON.parse(response.body)['hits']

    return hits
  end

end


# Entry point for testing the script
if __FILE__ == $0
  monitor = ElkMonitor.new(["good-container", "bad-container", "missed-container"])
  puts monitor.check
end
