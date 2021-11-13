#!/bin/sh

installBasePackages() {

	#
	# base packages
	#

	aptitude -y install ruby2.1
	aptitude -y install ruby-pg
	gem install ipaddr_extensions
}

installNASPackages() {

	#
	# nas packages
	#

	aptitude -y install openvpn
	##aptitude -y install openvpn-auth-radius
	##aptitude -y install easyrsa
	aptitude -y install strongswan

	#
	#  libs for accel-ppp
	#

	aptitude -y install libpcre++-dev	
	aptitude -y install libssl-dev
	aptitude -y install cmake

	#
	# accel-ppp
	#

	# add pushd

	cd /opt
	wget http://heanet.dl.sourceforge.net/project/accel-ppp/accel-ppp-1.8.0.tar.bz2
	tar xf ./accel-ppp-1.8.0.tar.bz2
	cd accel-ppp-1.8.0 
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DRADIUS=TRUE -DSHAPER=TRUE
	make
	make install

	#
	# ruby radiustar
	#

	cd /opt
	git clone https://github.com/pjdavis/radiustar

}

removeNASPackages() {

	#
	# ruby radiustar
	#

	rm -rf /opt/radiustar
	
	#
	# accel-ppp
	#

	cd /opt/accel-ppp-1.8.0 
	make uninstall
	rm -rf /opt/accel-ppp-1.8.0*

	#
	#  libs for accel-ppp
	#

	aptitude -y remove libpcre++-dev	
	aptitude -y remove libssl-dev
	aptitude -y remove cmake
	
	#
	# nas packages
	#

	aptitude -y remove openvpn
	##aptitude -y install openvpn-auth-radius
	##aptitude -y install easyrsa
	aptitude -y remove strongswan

}

makeNASConfig () {

	#
	# install nas script and files
	#
	cd $BASEDIR	
	./setupfiles.sh ./nas.list

}

installWebBillPackages() {

	#
	# main packages
	#

	aptitude -y install freeradius
	aptitude -y install freeradius-postgresql
	aptitude -y install strongswan
	aptitude -y install nginx
	aptitude -y install postgresql
	aptitude -y install php5-fpm
	aptitude -y install php5-dev
	aptitude -y install php5-curl
	aptitude -y install php5-mcrypt
	php5enmod mcrypt
	aptitude -y install php5-pgsql
	#aptitude -y install rabbitmq-server
}

removeWebBillPackages() {

	#
	# main packages
	#

	aptitude -y remove freeradius-postgresql
	aptitude -y remove freeradius
	aptitude -y remove strongswan
	aptitude -y remove nginx
	aptitude -y remove postgresql
	aptitude -y remove php5-curl
	aptitude -y remove php5-mcrypt
	aptitude -y remove php5-pgsql
	aptitude -y remove php5-dev
	aptitude -y remove php5-fpm
	#aptitude -y install rabbitmq-server
	
	rm -rf /opt/www
	rm -rf /opt/accounts

}

makeWebBillConfig () {

	cd $BASEDIR

	#
	# install webbill script and files
	#
	./setupfiles.sh ./webbill.list

	#
	# generate ca and host in ipsec.d
	#
	/opt/pki.sh genca
	/opt/pki.sh genhost server

        #
        # postgres
        #

        DBUSER='radius'
        DBPASSWD='radius'
        DBBASE='radius'

        echo "CREATE USER $DBUSER WITH LOGIN PASSWORD '$DBPASSWD';" > /tmp/crt.sql
        echo "CREATE DATABASE $DBBASE WITH OWNER $DBUSER ENCODING 'utf-8';" >> /tmp/crt.sql
	cd /tmp
        sudo -u postgres psql -U postgres < /tmp/crt.sql
        rm /tmp/crt.sql
        export PGPASSWORD=$DBPASSWD
        psql -U $DBUSER -h localhost $DBBASE < /etc/freeradius/sql/postgresql/nas.sql
        psql -U $DBUSER -h localhost $DBBASE < /etc/freeradius/sql/postgresql/schema.sql
        psql -U $DBUSER -h localhost $DBBASE < /opt/billscp.pg.2

        #
        # Site up
        #

        mkdir /opt/www
        chown -R root:www-data /opt/www
        chmod -R 775 /opt/www
        #scp -r root@www:/www/basic /opt/www/
}

BASEDIR=`pwd`

if [ ! -z "$1" ]; then
	echo "Do: $1"
fi

if [ "$1" = "installNas" ];then

	installBasePackages
	installNASPackages
	makeNASConfig

elif [ "$1" = "installWebbill" ];then

	installBasePackages
	installWebBillPackages
	makeWebBillConfig 

elif [ "$1" = "removeWebbill" ];then

	removeWebBillPackages

elif [ "$1" = "removeNas" ];then

	removeNASPackages
else
	echo "Usage: ./setup action"
	echo "Action: installNas (install NAS Server enviroment)"
	echo "        installWebbill (install Web and Billing enviroment)"
	echo "        removeNas (remove NAS Server enviroment)"
	echo "        removeWebbill (remove Web and Billing enviroment)"
fi

