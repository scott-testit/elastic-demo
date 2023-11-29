#!/bin/sh
# Assumes ElasticSearch is up and running on localhost port: 9200

# Create the mapping for the Shakespeare data
curl -H "Content-Type: application/json" -X PUT http://localhost:9200/shakespeare --data-binary @shakes-mapping.json

# retrieve it
curl -s http://localhost:9200/shakespeare

# Bulk upload data
