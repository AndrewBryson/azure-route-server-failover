# Overview

![Overview diagram](/images/azure-route-server-failover.png)

# Setup

## Create Virtual Network
- VNet `10.0.0.0/16`
- Subnets:
    - default: `10.0.0.0/24`
    - AzureRouteServer: `10.0.1.0/24`
    - servers: `10.0.2.0/24`

## Create Azure Route Server
1. Create in `RouteServerSubnet`
1. Add `10.0.2.10` and `10.0.2.20` as Peers on ASN `65010` (via Portal or otherwise) - if you don't do this then `exabgp` will be refused a connection.
1. These IP addresses will be used by the primary and secondary VMs.

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

# Verify
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

# Timings
These timings have been gathered crudely using aligned timestamps across VMs, nothing fancier than that!  Snippets of the terminal output have been shared for one attempt in each scenario, and other 3 timings given separately.

### Scenario 1 - primary to secondary failover (graceful termination)
Failover time: **<2 seconds**  
Start: 09:48:04  
End: 09:48:06   

Client
```
2021-11-23T09:48:06,123153999+00:00 + PRI
2021-11-23T09:48:06,236536190+00:00 + PRI
2021-11-23T09:48:06,354832563+00:00 + SEC
2021-11-23T09:48:06,468471959+00:00 + SEC
2021-11-23T09:48:06,581115537+00:00 + SEC
```

Primary
```
^C09:48:04 | 5652   | reactor       | ^C received
09:48:04 | 5652   | reactor       | performing shutdown
09:48:04 | 5652   | outgoing-1    | connection to 10.0.1.5 closed
09:48:04 | 5652   | outgoing-1    | outgoing-1 10.0.2.10-10.0.1.5, closing connection
09:48:04 | 5652   | outgoing-2    | connection to 10.0.1.4 closed
09:48:04 | 5652   | outgoing-2    | outgoing-2 10.0.2.10-10.0.1.4, closing connection
```

Secondary
```
09:48:04 | 4911   | outgoing-1    | received TCP payload (  19) FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 001C 02
09:48:04 | 4911   | outgoing-1    | received TCP payload (   9) 0005 200A 0100 0500 00
09:48:04 | 4911   | outgoing-1    | << message of type UPDATE
09:48:04 | 4911   | parser        | parsing UPDATE (   9) 0005 200A 0100 0500 00
09:48:04 | 4911   | parser        | announced NLRI none
09:48:04 | 4911   | parser        | NLRI      ipv4 unicast       without path-information     payload 200A 0100 05
09:48:04 | 4911   | parser        | withdrawn NLRI 10.1.0.5/32
09:48:04 | 4911   | outgoing-1    | receive-timer 29 second(s) left
09:48:04 | 4911   | peer-2        | << UPDATE #7
09:48:04 | 4911   | peer-2        |    UPDATE #7 nlri  (   5) 10.1.0.5/32
09:48:04 | 4911   | outgoing-2    | received TCP payload (  19) FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 001C 02
09:48:04 | 4911   | outgoing-2    | received TCP payload (   9) 0005 200A 0100 0500 00
09:48:04 | 4911   | outgoing-2    | << message of type UPDATE
09:48:04 | 4911   | parser        | parsing UPDATE (   9) 0005 200A 0100 0500 00
09:48:04 | 4911   | parser        | announced NLRI none
09:48:04 | 4911   | parser        | NLRI      ipv4 unicast       without path-information     payload 200A 0100 05
09:48:04 | 4911   | parser        | withdrawn NLRI 10.1.0.5/32
09:48:04 | 4911   | outgoing-2    | receive-timer 29 second(s) left
09:48:04 | 4911   | peer-1        | << UPDATE #7
09:48:04 | 4911   | peer-1        |    UPDATE #7 nlri  (   5) 10.1.0.5/32
09:48:05 | 4911   | outgoing-1    | send-timer 8 second(s) left
```

Other attempts:
1. <5 seconds
2. <4 seconds
3. <2 seconds

### Scenario 2 - secondary to primary recovery
Failover time: **<5 seconds**  
Start: 09:53:42  
End: 09:53:47  

Client
```
2021-11-23T09:53:47,117527920+00:00 + SEC
2021-11-23T09:53:47,233164386+00:00 + SEC
2021-11-23T09:53:47,346205116+00:00 + PRI
2021-11-23T09:53:47,459332348+00:00 + PRI
```

Primary
```
$ exabgp --debug ./conf.ini
09:53:42 | 6484   | welcome       | Thank you for using ExaBGP
09:53:42 | 6484   | version       | 4.0.2-1c737d99
09:53:42 | 6484   | interpreter   | 3.6.9 (default, Jan 26 2021, 15:33:00)  [GCC 8.4.0]
09:53:42 | 6484   | os            | Linux primary 5.4.0-1063-azure #66~18.04.1-Ubuntu SMP Thu Oct 21 09:59:28 UTC 2021 x86_64
```

Secondary
```
09:53:43 | 4911   | peer-2        | << UPDATE #8
09:53:43 | 4911   | peer-2        |    UPDATE #8 nlri  (   5) 10.1.0.5/32 next-hop 10.0.1.5
09:53:43 | 4911   | outgoing-2    | received TCP payload (  19) FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 003B 02
09:53:43 | 4911   | outgoing-2    | received TCP payload (  40) 0000 001F 4001 0100 4002 0A02 0200 00FF EB00 00FD F240 0304 0A00 0104 C008 04FF EDFF ED20 0A01 0005
09:53:43 | 4911   | outgoing-2    | << message of type UPDATE
09:53:43 | 4911   | parser        | parsing UPDATE (  40) 0000 001F 4001 0100 4002 0A02 0200 00FF EB00 00FD F240 0304 0A00 0104 C008 04FF EDFF ED20 0A01 0005
09:53:43 | 4911   | parser        | withdrawn NLRI none
09:53:43 | 4911   | parser        | attribute origin             flag 0x40 type 0x01 len 0x01 payload 00
09:53:43 | 4911   | parser        | attribute as-path            flag 0x40 type 0x02 len 0x0a payload 0202 0000 FFEB 0000 FDF2
09:53:43 | 4911   | parser        | attribute next-hop           flag 0x40 type 0x03 len 0x04 payload 0A00 0104
09:53:43 | 4911   | parser        | attribute community          flag 0xc0 type 0x08 len 0x04 payload FFED FFED
09:53:43 | 4911   | parser        | NLRI      ipv4 unicast       without path-information     payload 200A 0100 05
09:53:43 | 4911   | parser        | announced NLRI 10.1.0.5/32 next-hop 10.0.1.4
09:53:43 | 4911   | outgoing-2    | receive-timer 29 second(s) left
09:53:43 | 4911   | peer-1        | << UPDATE #8
09:53:43 | 4911   | peer-1        |    UPDATE #8 nlri  (   5) 10.1.0.5/32 next-hop 10.0.1.4
09:53:43 | 4911   | outgoing-1    | send-timer 9 second(s) left
```

Other attempts:
1. <1 second
2. <3 seconds
3. <1 second

### Scenario 3 - `kill -9` of primary `exabgp` (abrupt termination)

`kill` and timing method example:
```
andrewbryson@primary:~$ ps x | grep exabgp
 8655 pts/1    S+     0:00 /usr/bin/python3 /usr/sbin/exabgp --debug ./conf.ini
 8696 pts/0    S+     0:00 grep --color=auto exabgp
andrewbryson@primary:~$ date; kill -9 8655
Tue Nov 23 10:17:34 UTC 2021
```

Failover time: **<2 seconds**  
Start: 10:08:58
End: 10:09:00

Client
```
2021-11-23T10:17:36,562371918+00:00 + PRI
2021-11-23T10:17:36,674617289+00:00 + SEC
2021-11-23T10:17:36,788237474+00:00 + SEC
```

Primary
```
10:17:34 | 8655   | outgoing-1    | receive-timer 25 second(s) left
Killed
```

Secondary
```
10:17:34 | 4911   | outgoing-1    | received TCP payload (  19) FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 001C 02
10:17:34 | 4911   | outgoing-1    | received TCP payload (   9) 0005 200A 0100 0500 00
10:17:34 | 4911   | outgoing-1    | << message of type UPDATE
10:17:34 | 4911   | parser        | parsing UPDATE (   9) 0005 200A 0100 0500 00
10:17:34 | 4911   | parser        | announced NLRI none
10:17:34 | 4911   | parser        | NLRI      ipv4 unicast       without path-information     payload 200A 0100 05
10:17:34 | 4911   | parser        | withdrawn NLRI 10.1.0.5/32
10:17:34 | 4911   | outgoing-1    | receive-timer 29 second(s) left
10:17:34 | 4911   | peer-2        | << UPDATE #21
10:17:34 | 4911   | peer-2        |    UPDATE #21 nlri  (   5) 10.1.0.5/32
10:17:34 | 4911   | outgoing-2    | received TCP payload (  19) FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 001C 02
10:17:34 | 4911   | outgoing-2    | received TCP payload (   9) 0005 200A 0100 0500 00
10:17:34 | 4911   | outgoing-2    | << message of type UPDATE
10:17:34 | 4911   | parser        | parsing UPDATE (   9) 0005 200A 0100 0500 00
10:17:34 | 4911   | parser        | announced NLRI none
10:17:34 | 4911   | parser        | NLRI      ipv4 unicast       without path-information     payload 200A 0100 05
10:17:34 | 4911   | parser        | withdrawn NLRI 10.1.0.5/32
10:17:34 | 4911   | outgoing-2    | receive-timer 29 second(s) left
10:17:34 | 4911   | peer-1        | << UPDATE #21
10:17:34 | 4911   | peer-1        |    UPDATE #21 nlri  (   5) 10.1.0.5/32
```

Other attempts:
1. <1 second
2. <1 second
3. <2 seconds

Amazingly good failover times!

# Further Notes
1. Route changes seem to have a dampening/anti-flapping window of 30 seconds, i.e.
    1. Terminate the primary exabgp
    1. The route switches to secondary
    1. Then very quickly launch exabgp on the secondary again
    1. It will take 30 seconds from the initial failover before the primary becomes the effective route.
1. With equal `as-path` lengths you get a load balanced ECMP behaviour for traffic across primary and secondary servers.

# References
- https://docs.microsoft.com/en-us/azure/route-server/quickstart-configure-route-server-cli
- Demo inspired by Adam's great work: https://github.com/adstuart/azure-routeserver-anycast