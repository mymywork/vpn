#!/bin/sh

cd /etc/ipsec.d

if [ "$1" = "genca" ]
then
	if [ ! -f cacerts/ca.pem  ]
	then
		ipsec pki --gen --type rsa --size 2048 --outform pem > private/ca.key
		chmod 600 private/ca.key
		ipsec pki --self --ca --lifetime 3650 --in private/ca.key --type rsa --dn "C=CH, O=strongSwan, CN=strongSwan Root CA" --outform pem > cacerts/ca.pem
	else
		echo "CA Already exists."
	fi	
elif [ "$1" = "genhost" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi
	if [ ! -f cacerts/$2.pem ]
	then

		ipsec pki --gen --type rsa --size 2048 --outform pem > private/$2.key
		chmod 600 private/$2.key
		ipsec pki --pub --in private/$2.key --type rsa | ipsec pki --issue --lifetime 730 --cacert cacerts/ca.pem --cakey private/ca.key --dn "C=CH, O=strongSwan, CN=$3" --san @$3 --flag serverAuth --outform pem > certs/$2.pem
	else
		echo "Host cert certs/$2.pem exists!"
	fi

elif [ "$1" = "genclient" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi

	if [ -z $3]
	then
		CN=$2
	fi

	if [ ! -f cacerts/$2.pem ]
	then
		ipsec pki --gen --type rsa --size 2048 --outform pem > private/$2.key
		chmod 600 private/$2.key
		ipsec pki --pub --in private/$2.key --type rsa | ipsec pki --issue --lifetime 730 --cacert cacerts/ca.pem --cakey private/ca.key --dn "C=CH, O=strongSwan, CN=$CN" --san $CN   --flag clientAuth --outform pem > certs/$2.pem
	else
		echo "Client cert certs/$2.pem exists!"
	fi
elif [ "$1" = "gencrl" ]
then
	if [ ! -d ./crls ]
	then
		mkdir ./crls
	fi
	if [ ! -f crls/ca.crl ]
	then
		ipsec pki --signcrl --cacert cacerts/ca.pem --cakey private/ca.key --outform pem > crls/ca.crl
	else
		echo "Crls already exists."
	fi
elif [ "$1" = "revoke" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi
	ipsec pki --signcrl --cacert cacerts/ca.pem --cakey private/ca.key --lastcrl crls/ca.crl --cert certs/$2.pem > crls/ca.new
	cp crls/ca.crl crls/ca.old
	mv crls/ca.old crls/ca.crl
elif [ "$1" = "rm" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi

	rm /etc/ipsec.d/certs/$2.pem
	rm /etc/ipsec.d/private/$2.key
	rm /etc/ipsec.d/pkcs/$2.p12

elif [ "$1" = "export" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi

	if [ ! -d ./pkcs ]
	then
		mkdir ./pkcs
	fi

	if [ ! -d ./psw ]
	then
		mkdir ./psw
	fi

	openssl pkcs12 -export -in certs/$2.pem -inkey private/$2.key -certfile cacerts/ca.pem -out pkcs/$2.p12 -nodes -password pass: 
	#-passout #file:psw/$2.txt
elif [ "$1" = "export-psw" ]
then
	if [ -z $2 ]
	then
		echo "Certificate name not set."
		exit
	fi

	if [ ! -d ./pkcs ]
	then
		mkdir ./pkcs
	fi

	if [ ! -d ./psw ]
	then
		mkdir ./psw
	fi

	perl -e 'print int(rand(89999999)+10000000), "\n"' > psw/$2.txt
	openssl pkcs12 -export -in certs/$2.pem -inkey private/$2.key -certfile cacerts/ca.pem -out pkcs/$2.p12 -password file:psw/$2.txt 
else
	echo "Commands: "
	echo "./pki.sh genca - generate certification authority "
	echo "./pki.sh genhost <name> - generate host certificate"
	echo "./pki.sh genclient <name> <commonname> - generate client certificate"
	echo "./pki.sh gencrl - generate certificate revocation list"
	echo "./pki.sh revoke <name> - revoke certificate"
	echo "./pki.sh rm <name> - delete files of certificate"
	echo "./pki.sh export <name> - export pkcs12 without password "
	echo "./pki.sh export-psw <name> - export pkcs12 with password "
fi
