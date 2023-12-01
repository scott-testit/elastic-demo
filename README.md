# Elastic Search Demo

Topics we cover in this demo:
1. [Github Codespaces](https://github.com/features/codespaces)
2. [Docker / Docker Compose](https://github.com/compose-spec/compose-spec/blob/master/spec.md)
3. [ElasticSearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html) 
4. [Kibana](https://www.elastic.co/guide/en/kibana/current/index.html)

When working in Github Codespaces the IDE will frequently suggest installing different extensions as you open 
different types of files and run different commands, it's usually a good idea to click 
yes to install the extension as long as you know what the extension is related to.

## Create a Codespace

In this repo, click on the green "Code" icon and select Codespaces tab and click the plus sign to create a new codespace.
It will take a few seconds for the codespace to initialize.

## Install/Run ElasticSearch

Start here: https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html

Install using Docker: https://www.elastic.co/guide/en/elasticsearch/reference/8.11/docker.html

Create a `docker-compose.yml` file, or rather, edit the one in the 'work' directory

Note: the image, and port

Then, from the terminal, run:

`cd work`

then

`docker-compose up`

If you copy-paste the command above from this readme into the terminal, the codespace should
ask you if you want to give the browser access to your clipboard, click: yes or if you're using
Chrome you can click the icon in the address bar to the left of the URL and grant the codespace tab
access to your clipboard that way.

The codespace should ask you if you want to open the link in a browser, click yes. 
Note: If elasticsearch hasn't finished starting up when you open the link that's ok, 
refresh that tab later after ElasticSearch has finished initializing. You should be 
able to tell when it's done initializing by the logs being displayed in the terminal 
where the `docker-compose` command was run, since we ran it in the foreground.

We'll leave this terminal to run ES via docker-compose, and open another terminal to 
run the curl commands, by pressing the + button in the TERMINAL tab near the bottom right of VSCode

Use cUrl to validate ES is up and working correctly:

curl http://localhost:9200

curl "http://localhost:9200/_cat/nodes?v=true&pretty"

or in a different tab, go to the URL for the codespace name + ES port:

Run:

`echo "https://${CODESPACE_NAME}-9200.app.github.dev/"`

To see the URL where the codespace can be accessed

## Create the ES field mapping

First we need to create an ES index and specify a field mapping. 
This tells ES how to index and store each field of a document. 

We'll use Shakespeare data for this demo and someone has already 
created an ES mapping we can download using:

`wget http://media.sundog-soft.com/es7/shakes-mapping.json`

Create the index, specifying the mapping file we just downloaded 

`curl -H "Content-Type: application/json" -X PUT http://localhost:9200/shakespeare --data-binary @shakes-mapping.json`

This is called explicit mapping, ES also supports [dynamic mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-mapping.html) 
but we won't get into that here

Check out the info about the index, including the mapping:

`curl http://localhost:9200/shakespeare`

pretty output:

`curl -s http://localhost:9200/shakespeare?pretty`

Note: most of the ES APIs support the `pretty` query parameter

## The data

Now we need to index data into the ES index we created above

Download everything Shakespeare has ever written:

`wget http://media.sundog-soft.com/es7/shakespeare_7.0.json`

Look at a sample of the data in the file to get an idea what the data looks like: 

`less shakespeare_7.0.json`

Upload the JSON file using the bulk endpoint:

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

Try different text to search on:

Search for: 'The course of true love never did run smooth'

Search for: 'thine ownself be true'

`TEXT=<text to search for>`

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d "{ \"query\": { \"match_phrase\" : { \"text_entry\" : \"$TEXT\" } } }"`

Simple search using query params (supports Lucene syntax):

`curl "http://localhost:9200/shakespeare/_search?pretty&q=countrymen"`

(Without specifying a field ES searches all text fields I believe)

`curl "http://localhost:9200/shakespeare/_search?pretty&q=AEGEON"`

Specify a field to search:

`curl "http://localhost:9200/shakespeare/_search?pretty&q=line_number:1.1.12"`

Many attributes can be specified in the body of the request or via query params


## Return document by id

An 'id' field should be returned in results from the previous queries, use one of these
ids to find a document by id:

`curl http://localhost:9200/shakespeare/_doc/34229?pretty`

## Exact match on a specific field using a term query

Retrieve an entire play. Use a Term query to search for a specific 'term' in a specific field (exact match)
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-query.html

`curl -H "Content-Type: application/json" 'http://localhost:9200/shakespeare/_search?pretty' -d '{ "query": { "term" : { "play_name" : "Hamlet" } } }'`

## Pagination

By default, searches return 10 results, but you can use the `size` attribute to get more results back and `from` to specify a range.
This is useful when you need to page through a query's result set.

## Fields

By default, ES returns all fields of a document in the response of the query, specify the list of fields you want in the response by 
adding a list of fields in the request (see below)

## Sort

Specify a sort on integer field, like: `line_id` 

Numeric fields work best for sorting, keyword fields can also be used for sorting, but text fields cannot be used for sorting (by default)

# Composite Queries

To do more complicated queries, with multiple clauses we need to use a composite query with boolean clauses:
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html

To see only 'line' type documents for the play hamlet, copy-paste the following into a terminal:

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

## Kibana

Before starting this section, make sure that you kill (ctrl-c) the terminal that's running docker-compose in order to 
kill the existing elastic search container. 

Alternatively, open a new terminal and run: 

`docker ps`

to find running containers 

`docker stop <CONTAINER ID>`

to stop the ES container 

Then run: 

`docker system prune -f`

To cleanup stopped containers to prepare for running ElasticSearch and Kibana in this section.

Kibana is a great UI for connecting to ElasticSearch indexes to do searches, load data, visualize data etc.
There are a ton of integrations and neat things you can do with your data in Kibana.

Run ElasticSearch and Kibana together:
Reference: https://www.elastic.co/guide/en/kibana/current/docker.html

Kibana runs as a separate container/application but needs to talk to ElasticSearch,
so we'll run them both together using docker-compose.

In a new terminal window go to the `solution/kibana` directory:

`cd solution/kibana`

Then run:

`docker-compose up`

This should start both ElasticSearch container (es01) and Kibana container (kib01)

Look for the Kibana auth code in the output of the docker-compose command, it should be at the bottom
after Kibana has finished starting up and look something like:

`Go to http://0.0.0.0:5601/?code=796098 to get started.`

If you can't find that line in the logs of the docker-compose command, you can search for it.

In another terminal run:

`docker logs kib01 | grep code`

Now go to Kibana UI in another tab, either by pressing the "open in browser" that popped up when you ran 
docker-compose, or you can open a new tab for Kibana by going to the "PORTS" tab (right next to "TERMINAL"),
then under "Forwarded Address" for port 5601 click the globe icon to "Open in Browser"

Next you need to configure Kibana to connect to ElasticSearch manually since it's running unsecured on the same network. 
Select "Configure Manually" and use the URL: http://es01:9200

(es01 is the hostname of the ElasticSearch container running Docker)

Then "Check Address" -> "Configure Elastic"

You may be asked here to enter the verification code we got from the docker logs earlier

### Using Kibana

Once Kibana is setup and connected to the ElasticSearch instance, we need to load documents back into ES in 
order to explore them in Kibana. 

To add the shakespeare documents to ES, open a new terminal and go to `solution/shakespeare` directory and run:

`./setup.sh`

This will create the Shakespeare index again and upload all of the Shakespeare JSON data. This can take a couple
of minutes to load all of the JSON data via the bulk endpoint. Since we've configured a volume for ElasticSearch
to use in the `docker-compose.yml` file document data should persist restarts and we won't have to do this again
even if the containers are restarted.

Once the data is loaded in ES, go back to the Kibana UI and 
check out the index by accessing the navigation menu by clicking the 3 lines near the top left of the page. 
Then under: Management, select Stack Management -> Index Management

Then click on the shakespeare index to see stats and settings for the index.
To explore the document data, press the "Discover Index" button and "Create data view"

Create a data view by giving it a name (whatever you like) and shakespeare under index pattern and save.

Now you can explore the data using the filter box, and entering a KQL query to filter data by criteria. 
See if you can recreate the queries we did in curl using this interface

There are a ton of things you can do in Kibana. If you want to try importing data and creating a new ElasticSearch index,
you can do that by going to the navigation menu on the left -> Machine Learning -> Visualize Data from File -> Import a CSV

For a good CSV to import, in VSCode go under solution/kibana/ml-latest-small and rick click the 'tags.csv' file and download it 
to your local machine.
Now you can import that CSV into ElasticSearch using Kibana

This data is not all that useful becaues it has movieId rather than movie name. It's designed to be used with 
the movies.csv file from the dataset that contains moveIds and associated movie title. An interesting exercise would
be to figure out how to load both CSVs into Kibana so they can be used together.


## Creating a website using ElasticSearch as a back-end

To demonstrate how you might use ElasticSearch to power a website, we'll use the shakespeare index 
created in previous sections and a simple HTML page (with some JS) to query ES.

In the VSCode Explorer, open the file: solution -> website -> index.html

Edit the index.html and update the `const URL` variable to point to your codespace URL.

To find the Codespace URL, from a terminal run:

`echo "https://${CODESPACE_NAME}-9200.app.github.dev/shakespeare/_search"`

Then copy that URL and replace it in the index.html file.

Now service up the HTML by running the following from a terminal:

`cd solution/website`

`./serve.sh`

This will start a simple http file server for the HTML. 
Then click "Open in Browser" 

To avoid CORS issues and make this work we have to change the ElasticSearch port to be public:
Under the "PORTS" tab (next to TERMINAL), right click on port 9200 and change Port Visibility to: Public

The webpage should now be able to call the ElasticSearch API running inside your codespace.
