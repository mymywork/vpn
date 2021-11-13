#!/bin/sh
login=$1
base='/opt/accounts'

cd /etc/ipsec.d/
./pki.sh genclient $login
./pki.sh export $login
mkdir ${base}/${login}/
mkdir ${base}/${login}/servers

cp /etc/ipsec.d/pkcs/${login}.p12 ${base}/${login}/${login}.p12

while read line
do
	if [ -z "$line" ]; then
		continue
	fi
	locate=`echo ${line%%=*} | sed -e 's/^ *//' -e 's/ *$//'`
	ip=`echo ${line#*=} |  sed -e 's/^ *//' -e 's/ *$//'`

	cat ${base}/ovpndefault.conf | sed -e "s/pkcs12 default.p12/pkcs12 ${login}.p12/g" | sed -e "s/remote 127.0.0.1/remote ${ip}/g" > ${base}/${login}/servers/${locate}.conf
	
done < ${base}/servers.txt

cd ${base}/${login}/

zip -r ../${login}.zip .
