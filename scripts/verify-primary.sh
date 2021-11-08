#!/bin/bash

az \
    network routeserver peering list-learned-routes \
    -g vip \
    --routeserver vip \
    --name primary