# Install node.js (web server) and ExaBGP
sudo apt update
sudo apt install -y exabgp
curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install -y nodejs

# Loopback VIP (10.1.0.5) configuration
#sudo ifconfig lo:9 10.1.0.5 netmask 255.255.255.255 up
sudo ip link add name vip type dummy \
    && ifconfig vip 10.1.0.5 netmask 255.255.255.255 up

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
	static {
		route 10.1.0.5/32 next-hop $IP;
	}
}
neighbor $ARS2 {
	router-id $IP;
	local-address $IP;
	local-as $MY_ASN;
	peer-as $REMOTE_ASN;
	static {
		route 10.1.0.5/32 next-hop $IP;
	}
}
EOF



## Start ExaBGP
exabgp ./conf.ini