#!/bin/bash
# Provisioning file for Vagrant

# Common setup for all servers

. /vagrant/provisioning/config.sh

echo "Changing QGIS_SERVER_DIR to ${QGIS_SERVER_DIR} ..."

# Add repositories
apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811
echo 'deb http://qgis.org/debian xenial main' > /etc/apt/sources.list.d/debian-gis.list
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-get update

# Install the software
export DEBIAN_FRONTEND=noninteractive
apt-get -y install qgis-server python-qgis xvfb

# Install utilities (optional)
apt-get -y install vim unzip

# Install sample projects and plugins
mkdir -p $QGIS_SERVER_DIR/logs
cp -r /vagrant/resources/web/htdocs $QGIS_SERVER_DIR
cp -r /vagrant/resources/web/plugins $QGIS_SERVER_DIR
cp -r /vagrant/resources/web/projects $QGIS_SERVER_DIR
chown -R www-data.www-data $QGIS_SERVER_DIR

# Setup xvfb
cp /vagrant/resources/xvfb/xvfb.service /etc/systemd/system/xvfb.service
systemctl enable /etc/systemd/system/xvfb.service
service xvfb start

# Symlink to cgi for apache CGI mode
ln -s /usr/lib/cgi-bin/qgis_mapserv.fcgi /usr/lib/cgi-bin/qgis_mapserv.cgi