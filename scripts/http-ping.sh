#!/bin/bash

URL=http://10.1.0.5:3000

while :; do 
    echo \
    $(date) + $(curl --silent --no-keepalive -H 'Connection: close' $URL); 
    sleep 1s; 
done