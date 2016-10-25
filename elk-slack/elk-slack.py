from elasticsearch import Elasticsearch
from slacker import IncomingWebhook
import datetime


# Settings
link = "http://your-kibana.com/kibana/app/kibana#/doc/logstash-*/%s/%s?id=%s"


# Init clients
client = Elasticsearch(
    hosts=['http://127.0.0.1:9200']
)
slack = IncomingWebhook(url='https://hooks.slack.com/services/XXX/YYY/ZZZ')


# Read the black list
black_list = [line.strip() for line in open("black.list", 'r')]
black_list = [line for line in black_list if line]
#print(black_list)


query = {"match_all": {}}
if black_list:
    exclude_data = {"must_not": []}

    for error in black_list:
        exclude_data.get('must_not').append({
            "query_string": {
                "default_field": "message",
                "minimum_should_match": "100%",
                "query": error
            }
        })

    query = {"bool": exclude_data}
#print(query)
#exit()


# Build the search query
es_request = {
    "query": query,
    "filter": {
        "and": [
            {"term": {"level.raw": "ERROR"}},
            {"range": {"@timestamp": {"gte": "now-1m"}}}
        ]
    }
}


# Get errors
index = datetime.datetime.now().strftime("logstash-%Y.%m.%d")
errors = client.search(index=index, body=es_request, size=5)


# Send message to Slack
for error in errors['hits']['hits']:

    error_link = link % (error['_index'], error['_type'], error['_id'])
    message = "*" + (error["_source"]["component"] if 'component' in error["_source"] else "python") + "*: " + \
              error["_source"]["message"]
    message += "\n*Link*: " + error_link

    if 'stack_trace' in error["_source"]:
        message += "\n\n```" + error["_source"]["stack_trace"][:500] + "```"

    #print(message)
    slack.post({"text": message})

