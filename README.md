# README

# Steps

## Create Virtual Network
- VNet 10.0.0.0/16
- Subnets:
    - default: 10.0.0.0/24
    - AzureRouteServer: 10.0.1.0/24
    - servers: 10.0.2.0/24

## Create jumpbox as a client VM
- Simple low-spec ubuntu VM
- SSH jumpbox and pretend web client

## Create primary and secondary VMs with web app
- Simple low-spec ubuntu VMs
- Placed in 'servers' subnet
- Private IP only

### Web app
```
sudo apt update -y && sudo apt install -y nodejs
```

### IP addresses
- Primary: 10.0.2.10
- Secondary: 10.0.2.20

## Create Azure Route Server
Commands in order
1. Create in `RouteServerSubnet`
1. Add `10.0.2.10` and `10.0.2.20` as Peers (via Portal or otherwise) - if you don't do this then `exabgp` will not connect.
1. 

## Configure exabgp

## Verify
1. Ping from jumpbox: `ping 9.9.9.9`
1. Web request: `curl http://9.9.9.9:3000`
1. Run `$/scripts/http-ping.sh`.

# Documentation References
- https://docs.microsoft.com/en-us/azure/route-server/quickstart-configure-route-server-cli
- 