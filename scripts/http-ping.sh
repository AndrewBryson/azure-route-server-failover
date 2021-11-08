#!/bin/bash

URL=http://9.9.9.9:3000

while :; do 
    echo \
    $(date) + $(curl --silent --no-keepalive -H 'Connection: close' $URL); 
    sleep 1s; 
done