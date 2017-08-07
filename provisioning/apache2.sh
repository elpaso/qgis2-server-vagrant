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
# Clean all existing website configurations just to be sure
rm -rf /etc/apache2/sites-enabled/*.conf
# Clean odd configs when deploying on an osgeolive
rm -f /etc/apache2/conf-enabled/qgis*.conf
rm -f /etc/apache2/conf-enabled/*wsgi.conf
rm -f /etc/apache2/conf-enabled/eoxserver.conf
# Enable the website configuration for QGIS Server
a2ensite 001-qgis-server

# Listen on port 81 instead of 80 (nginx)
sed -i -e 's/Listen 80/Listen 81/' /etc/apache2/ports.conf
sed -i -e 's/VirtualHost \*:80/VirtualHost \*:81/' /etc/apache2/sites-available/001-qgis-server.conf
# Restart the server
service apache2 restart
