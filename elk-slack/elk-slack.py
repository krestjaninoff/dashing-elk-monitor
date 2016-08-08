from elasticsearch import Elasticsearch
from slacker import IncomingWebhook
import datetime


# Init clients
client = Elasticsearch(
    hosts=['http://127.0.0.1:9200']
)
slack = IncomingWebhook(url='https://hooks.slack.com/services/XXX/YYY/ZZZ')


# Read the black list
black_list = [line.strip() for line in open("black.list", 'r')]
exclude_data = {"must_not": []}
for error in black_list:
    exclude_data.get('must_not').append({
        "query_string": {
            "default_field": "message",
            "minimum_should_match": "100%",
            "query": error
        }
    })
#print(exclude_data)
#exit()


# Build the search query
es_request = {
    "query": {"bool": exclude_data},
    "filter": {
        "and": [
            {"term": {"level.raw": "ERROR"}},
            {"range": {"@timestamp": {"gte": "now-2m"}}}
        ]
    }
}


# Get errors
index = datetime.datetime.now().strftime("logstash-%Y.%m.%d")
errors = client.search(index=index, body=es_request, size=20)


# Send message to Slack
for error in errors['hits']['hits']:

    message = error["_source"]["message"]
    if 'stack_trace' in error["_source"]:
        message += "\n\n" + error["_source"]["stack_trace"][:500]

    #print(message)
    slack.post({"text": message})

