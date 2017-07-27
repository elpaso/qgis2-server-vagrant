#!/bin/bash
# Provisioning file for Vagrant: nginx + uwsgi

. /vagrant/provisioning/config.sh

echo "Changing QGIS_SERVER_DIR to ${QGIS_SERVER_DIR} ..."

# Install the software
export DEBIAN_FRONTEND=noninteractive
apt-get -y install nginx uwsgi

# Configure the web server
rm /etc/nginx/sites-enabled/default
cp /vagrant/resources/nginx/qgis-server /etc/nginx/sites-enabled
sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@" /etc/nginx/sites-enabled/qgis-server

# Configure uwsgi
cp /vagrant/resources/uwsgi/uwsgi-qgis.service /etc/systemd/system/uwsgi-qgis.service
cp /vagrant/resources/uwsgi/qgis-server.ini /etc/uwsgi/apps-enabled/qgis-server.ini
sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@" /etc/uwsgi/apps-enabled/qgis-server.ini
systemctl enable /etc/systemd/system/uwsgi-qgis.service
service uwsgi-qgis start


# Restart the server
/etc/init.d/nginx restart
