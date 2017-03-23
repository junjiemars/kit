#!/bin/bash

export VAR_NAME="xYz"

echo $(envsubst < "a.json")
#echo $(eval echo $(cat a.json)) 

#curl -v -H "Content-Type: application/json" -d@b.json 'https://httpbin.org/post'
