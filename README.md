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

# Issues / Questions / Notes

1. Issue: Can the primary and secondary VMs be registered with the same local ASN?  I had issues, `exabgp` failed to communicate with ASR.  Registering peers within ASR using different ASNs fixed the problem.
1. Issue: Experimenting with the 'MED' attribute for routes like [ `route 10.1.0.5/32 next-hop 10.0.2.10 med 10;`, `route 10.1.0.5/32 next-hop 10.0.2.10 med 50;` ] I see load-balancing-like behaviour where the jumpbox VM sending a `curl http://vip:3000` every 1 second gets interleaved results from both the primary and secondary servers:
```
...
Tue Nov 9 09:41:39 UTC 2021 + PRI
Tue Nov 9 09:41:40 UTC 2021 + PRI
Tue Nov 9 09:41:41 UTC 2021 + PRI
Tue Nov 9 09:41:42 UTC 2021 + SEC
Tue Nov 9 09:41:43 UTC 2021 + PRI
Tue Nov 9 09:41:44 UTC 2021 + SEC
Tue Nov 9 09:41:45 UTC 2021 + SEC
Tue Nov 9 09:41:46 UTC 2021 + PRI
...
```

3. Note: With both BGP speakers stopped, then starting the primary, the HTTP client begins working within a couple of seconds.
4. Note: Stopping the primary BGP speaker breaks the HTTP client within a couple of seconds.  Routes updated very quickly?
5. Note: Contrary to the above 2 notes, on further attempts it took about 10 seconds to have an effective working route.
6. Note: With both BGP speakers, secondary.as-path length = 1, and primary.as-path length = 3, the secondary route is preferred, as expected.
7. Note: Following #6 above, terminating the secondary BGP speaker fails over to the primary route almost immediately.  This simulates a 'fail back' approach.
8. 


# Documentation References
- https://docs.microsoft.com/en-us/azure/route-server/quickstart-configure-route-server-cli
- 