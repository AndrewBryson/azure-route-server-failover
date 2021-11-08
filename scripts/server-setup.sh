# Install node.js (web server) and ExaBGP
sudo apt update
sudo apt install -y nodejs exabgp

# Loopback VIP (9.9.9.9) configuration
#sudo ifconfig lo:9 9.9.9.9 netmask 255.255.255.255 up
sudo ip link add name vip type dummy \
    && ifconfig vip 9.9.9.9 netmask 255.255.255.255 up

# ExaBGP config
ARS1=10.0.1.4
ARS2=10.0.1.5
MY_ASN=65010
REMOTE_ASN=65515
IP=$(ifconfig eth0 | grep 'inet' | grep -v 'inet6' | gawk '{print $2}')

cat > conf.ini <<EOF
neighbor $ARS1 {
	router-id $IP;
	local-address $IP;
	local-as $MY_ASN;
	peer-as $REMOTE_ASN;
}
neighbor $ARS2 {
	router-id $IP;
	local-address $IP;
	local-as $MY_ASN;
	peer-as $REMOTE_ASN;
}
EOF

# static {
# 	route 9.9.9.9/32 next-hop $IP [ 65010 65010 65010 ];
# 	}

## Start ExaBGP
exabgp ./conf.ini