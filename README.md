# Elastic Search Demo

## Install/Run ElasticSearch

Start here: https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html

Install using Docker: https://www.elastic.co/guide/en/elasticsearch/reference/8.11/docker.html

Create a `docker-compose.yml` file, or rather, edit the one in the 'work' directory

Note: the image, and port

Then run:
`docker-compose up`

Use cUrl to validate it's up and working correctly:

curl http://localhost:9200

curl "http://localhost:9200/_cat/nodes?v=true&pretty"

or in a different tab, go to: https://<codespace name>-9200.app.github.dev/

## Create the ES field mapping

This tells ES how to index and store each field of a document

Download the Shakespeare mapping:

`wget http://media.sundog-soft.com/es7/shakes-mapping.json`

Create the mapping 

`curl -H "Content-Type: application/json" -X PUT http://localhost:9200/shakespeare --data-binary @shakes-mapping.json`

This is called explicit mapping, ES also supports dynamic mapping which we won't get into here

Check the info about the index, including the mapping:

`curl http://localhost:9200/shakespeare`

pretty output:

`curl -s http://localhost:9200/shakespeare?pretty`

## The data

Now we need to index data into the ES index

Download everything Shakespeare has ever written:
`wget http://media.sundog-soft.com/es7/shakespeare_7.0.json`


Upload the JSON using the bulk endpoint:

`curl -H "Content-Type: application/json" -X POST 'http://localhost:9200/shakespeare/_bulk' --data-binary @shakespeare_7.0.json`

Now look at the index info again:

`curl -s http://localhost:9200/shakespeare | json_pp`


# Explore the data

Number of docs:

`curl -s http://localhost:9200/shakespeare/_count`

Search

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d '{ "query": { "match_phrase" : { "text_entry" : "to be or not to be" } } }'`

Retrieve an entire play

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d '{ "query": { "match_phrase" : { "text_entry" : "to be or not to be" } } }'`




