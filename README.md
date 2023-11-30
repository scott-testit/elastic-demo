# Elastic Search Demo

## Install/Run ElasticSearch

Start here: https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html

Install using Docker: https://www.elastic.co/guide/en/elasticsearch/reference/8.11/docker.html

Create a `docker-compose.yml` file, or rather, edit the one in the 'work' directory

Note: the image, and port

Then run:

`docker-compose up`

The codespace should ask you if you want to open the link in a browser

Use cUrl to validate it's up and working correctly:

curl http://localhost:9200


curl "http://localhost:9200/_cat/nodes?v=true&pretty"

or in a different tab, go to the URL for the codespace name + ES port:

Run:

`echo "https://${CODESPACE_NAME}-9200.app.github.dev/"`


## Create the ES field mapping

This tells ES how to index and store each field of a document

Download the Shakespeare mapping:

`wget http://media.sundog-soft.com/es7/shakes-mapping.json`

Create the index, specifying a mapping 

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

Look at a sample of the data in: 

`shakespeare_7.0.json`

Upload the JSON using the bulk endpoint:

`curl -H "Content-Type: application/json" -X POST 'http://localhost:9200/shakespeare/_bulk' --data-binary @shakespeare_7.0.json`

Now look at the index info again:

`curl -s http://localhost:9200/shakespeare?pretty`

ES chose 'text' field type by default for the `text_entry` field

# Explore the data

Number of docs:

`curl -s http://localhost:9200/shakespeare/_count`

## Search

The Search API is expansive

Reference:
* https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html
* https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html


## Search for a word or a phrase 

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d '{ "query": { "match_phrase" : { "text_entry" : "to be or not to be" } } }'`

Search for: 'The course of true love never did run smooth'
Search for: 'thine ownself be true'

`TEXT=<text to search for>`

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d "{ \"query\": { \"match_phrase\" : { \"text_entry\" : \"$TEXT\" } } }"`

## Return document by id

`curl http://localhost:9200/shakespeare/_doc/34229?pretty`

## Exact match on a specific field using a term query

Retrieve an entire play. Use a Term query to search for a specific 'term' in a specific field (exact match)
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-query.html


`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d '{ "query": { "term" : { "play_name" : "Hamlet" } } }'`

## Pagination

By default, searches return 10 results, but you can use the `size` attribute to get more results back and `from` to specify a range.

Like many attributes, this can be specified in the body of the request or in query params

## Fields

By default, ES returns all fields in the response of the query (I think?), specify the list of fields you want in the response by 
specifying those list of fields in the request (see below)

## Sort

Specify a sort on integer field: `line_id` 

Numeric fields work best for sorting, but some keyword fields can also be used, but can't sort on text fields)


# Composite Queries

More complicated queries, or composite queries, we need to a boolean query:
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html

To see only 'line' type documents for the play hamlet:

```
QUERY=$(cat <<-END
    { 
        "query": {
            "bool" : {
                "must" : {
                    "term" : { "play_name" : "Hamlet" }
                },
                "filter" : {
                    "term" : { "type" : "line" }
                }        
            }      
        },
        "fields": [
            "line_number",
            "speaker",
            "text_entry"
        ]
    }
END
)
```


Now use the variable in the curl command

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty&_source=false&sort=line_id&size=100' -d "$QUERY"`


# Analyze the index



