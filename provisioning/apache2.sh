#!/bin/bash
# Provisioning file for Vagrant: apache2

. /vagrant/provisioning/config.sh

echo "Changing QGIS_SERVER_DIR to ${QGIS_SERVER_DIR} ..."

# Install the required server software
export DEBIAN_FRONTEND=noninteractive
apt-get -y install apache2 libapache2-mod-fcgid


# Configure the web server
cp /vagrant/resources/apache2/001-qgis-server.conf /etc/apache2/sites-available
sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@g" /etc/apache2/sites-available/001-qgis-server.conf
sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@g" $QGIS_SERVER_DIR/htdocs/index.html
a2enmod rewrite
a2enmod cgid
a2dissite 000-default 
a2ensite 001-qgis-server

# Listen on port 81 instead of 80 (nginx)
sed -i -e 's/Listen 80/Listen 81/' /etc/apache2/ports.conf

# Restart the server
service apache2 restart
