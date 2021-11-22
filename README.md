# Overview

![Overview diagram](/images/azure-route-server-failover.png)

# Steps

## Create Azure Route Server
1. Create in `RouteServerSubnet`
1. Add `10.0.2.10` and `10.0.2.20` as Peers on ASN `65515` (via Portal or otherwise) - if you don't do this then `exabgp` will be refused a connection.
1. These IP addresses will be used by the priamry and secondary VMs.

## Create jumpbox as a client VM
- Simple low-spec ubuntu VM
- SSH jumpbox and pretend web client

### Start http-ping
1. On the client/jumpbox VM run the script: [http-ping.sh](/scripts/http-ping.sh).
1. You will see output like:
```
2021-11-22T14:46:35,983290736+00:00 +
2021-11-22T14:46:37,096042443+00:00 +
```
That shows: `{Date}T{Time} + {Server ID}`.  If nothing appears after the `+` that's because no reply was received from the VIP (=`10.1.0.5`).  That's okay, the servers aren't setup yet.

## Create Virtual Network
- VNet `10.0.0.0/16`
- Subnets:
    - default: `10.0.0.0/24`
    - AzureRouteServer: `10.0.1.0/24`
    - servers: `10.0.2.0/24`

## Create primary and secondary VMs with web app
- Simple low-spec ubuntu VMs
- Placed in `servers` subnet, private IPs only
- Primary IP = `10.0.2.10`
- Secondary = `10.0.2.20`

### Web app creation
1. On the primary and secondary VMs, review the script: [server-setup.sh](/scripts/server-setup.sh).  This installs the dependencies `node` and `exabgp` and configures the VIP with `ifconfig`.
1. Run the script.
1. Launch the web server, e.g.
    1. Primary server: `ID=PRI node ./web/server.js &`
    2. Secondary server: `ID=SEC node ./web/server.js &`
1. That command uses `&` to fork the process into the background.  Use `fg` to bring it back to the foreground.

### Configure exabgp
1. On the primary VM run:
    1. [primary-exabgp-setup.sh](/scripts/primary-exabgp-setup.sh).  This creates a file in the current directory called `conf.ini`.
    1. Launch exabgp: `exabgp --debug ./conf.ini`
    1. At this point the `http-ping` on the client/jumpbox should start to provide responses.
1. On the secondary VM run:
    1. [secondary-exabgp-setup.sh](/scripts/secondary-exabgp-setup.sh).  This creates a file in the current directory called `conf.ini`.
    1. Launch exabgp: `exabgp --debug ./conf.ini`

`exabgp` should now be running on both primary and secondary VMs.

## Verify
Normal state of [http-ping.sh](/scripts/http-ping.sh) will see a response like:
```
...
2021-11-22T14:51:42,102116071+00:00 + PRI
2021-11-22T14:51:42,214647212+00:00 + PRI
...
```
Showing responses coming from the primary VM.

Now perform a `Ctrl+C` of the `exabgp` process on the primary VM, within a couple of seconds the response should failover to the secondary VM:
```
...
2021-11-22T14:53:15,744081418+00:00 + PRI
2021-11-22T14:53:15,856580859+00:00 + PRI
2021-11-22T14:53:15,969329001+00:00 + SEC // failed over ✅
2021-11-22T14:53:16,082586449+00:00 + SEC
2021-11-22T14:53:16,196167799+00:00 + SEC
...
```
This example snippet showing the VIP effective route failing over to the secondary VM.

## Timings
These timings have been gathered crudely using aligned timestamps across VMs, nothing fancier than that!

### Scenario 1 - primary to secondary failover


# Further Notes
1. Route changes seem to have a dampening/anti-flapping window of 30 seconds, e.g.
    1. Terminate the primary exabgp
    1. The route switches to secondary
    1. Then very quickly launch exabgp on the secondary again
    1. Tt will take 30 seconds from the initial failover before the primary becomes the effective route.
1. With equal `as-path` lengths you get a load balanced ECMP behaviour for traffic across primary and secondary servers.

# Documentation References
- https://docs.microsoft.com/en-us/azure/route-server/quickstart-configure-route-server-cli
- 