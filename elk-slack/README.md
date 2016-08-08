# An utility for forwarding errors from ElasticSearch to Slack

Just a tiny script which invokes ES HTTP interface to retrieve new errors and posts them into a Slack channel through Slack's web hook (which must be preconfigured).

### Installation

First of all, you have to install python and necessary libraries:

```
apt-get install python pip
pip install elasticsearch
pip install slacker
```

Currently, the scripts asumes to started through the crontab. See `cron.tab` file for example.

### Blacklisting

The scripts also supports balcklisting, so that you can avoid recieving known errors which won't be fixed in the closest future.

