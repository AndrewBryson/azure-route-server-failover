# Secondary ExaBGP config
MY_ASN=65011

ARS1=10.0.1.4
ARS2=10.0.1.5
VIP=10.1.0.5/32
IP=$(ifconfig eth0 | grep 'inet' | grep -v 'inet6' | gawk '{print $2}')
REMOTE_ASN=65515

cat > conf.ini <<EOF
neighbor $ARS1 {
	router-id $IP;
	local-address $IP;
	local-as $MY_ASN;
	peer-as $REMOTE_ASN;
	static {
		route $VIP next-hop $IP as-path [ $MY_ASN ];
	}
}
neighbor $ARS2 {
	router-id $IP;
	local-address $IP;
	local-as $MY_ASN;
	peer-as $REMOTE_ASN;
	static {
		route $VIP next-hop $IP as-path [ $MY_ASN ];
	}
}
EOF
