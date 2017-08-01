:data-transition-duration: 2000
:skip-help: true
:css: css/custom.css

.. title:: QGIS Server Workshop 2017

.. header::

   .. image:: images/qgis-icon.png


.. footer::

    Introduction to QGIS Server Workshop 2017

----

OS Setup
====================

We are using Ubuntu Xenial 64bit

in Vagrant is it provided by the *box*:


.. code:: python

    config.vm.box = "ubuntu/xenial64"

.. code:: bash

    vagrant up --no-provision
    # or just "vagrant up" if you want to provision

----

SSH into the machine
====================

.. code:: bash

    vagrant ssh
    sudo su -

**Checkpoint**: you need to be able to log into the machine and become `root`

----

Add resources from workshop repository
======================================

Only for unprovisioned machines!

.. code:: bash

    wget https://github.com/elpaso/qgis2-server-vagrant/archive/master.zip
    unzip master.zip 
    rmdir /vagrant/
    mv qgis2-server-vagrant-master/ /vagrant

----

Add required repositories
=========================

.. code:: bash

    # Add QGIS repositories
    apt-key adv --keyserver keyserver.ubuntu.com --recv-key 073D307A618E5811
    echo 'deb http://qgis.org/debian xenial main' > \
        /etc/apt/sources.list.d/debian-gis.list
    apt-get update

----

Add required repositories
=========================

**Checkpoint**: the available version of qgis-server must be >= 2.18.11 from qgis.org

.. code:: bash

    root@ubuntu-xenial:~# apt-cache policy qgis-server
    qgis-server:
    Candidate: 1:2.18.11+24xenial
    Version table:
    *** 1:2.18.11+24xenial 500
            500 http://qgis.org/debian xenial/main amd64 Packages


----

Install system software
=======================

Install the software

.. code:: bash

    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install qgis-server python-qgis xvfb

    # Install utilities (optional)
    apt-get -y install vim unzip


----

Install system software I
===========================

**Checkpoint**: qgis installed with no errors, you can check it with

.. code:: bash

    root@ubuntu-xenial:~# /usr/lib/cgi-bin/qgis_mapserv.fcgi
    Content-Length: 206
    Content-Type: text/xml; charset=utf-8

    <ServiceExceptionReport version="1.3.0" xmlns="http://www.opengis.net/ogc">
    <ServiceException code="Service configuration error">
            Service unknown or unsupported</ServiceException>
    </ServiceExceptionReport>


----

Install system software II
===========================


.. code:: bash

    # Install sample projects and plugins
    mkdir -p $QGIS_SERVER_DIR/logs
    cp -r /vagrant/resources/web/htdocs $QGIS_SERVER_DIR
    cp -r /vagrant/resources/web/plugins $QGIS_SERVER_DIR
    cp -r /vagrant/resources/web/projects $QGIS_SERVER_DIR
    chown -R www-data.www-data $QGIS_SERVER_DIR


----

Install system software III
=============================

.. code:: bash

    # Setup xvfb
    cp /vagrant/resources/xvfb/xvfb.service \
        /etc/systemd/system/xvfb.service
    systemctl enable /etc/systemd/system/xvfb.service
    service xvfb start

    # Symlink to cgi for apache CGI mode
    ln -s /usr/lib/cgi-bin/qgis_mapserv.fcgi \
        /usr/lib/cgi-bin/qgis_mapserv.cgi

----

Apache2
======================

Installation (with FCGI module)

.. code:: bash 

    # Common configuration
    export QGIS_SERVER_DIR=/qgis-server

    # Install the required server software
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install apache2 libapache2-mod-fcgid


-----

Apache2 configuration I
=========================

Configure the web server

.. code:: bash 

    cp /vagrant/resources/apache2/001-qgis-server.conf \
        /etc/apache2/sites-available
    sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@g" \
        /etc/apache2/sites-available/001-qgis-server.conf
    sed -i -e 's/VirtualHost \*:80/VirtualHost \*:81/' \
        /etc/apache2/sites-available/001-qgis-server.conf
    sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@g" \
        $QGIS_SERVER_DIR/htdocs/index.html



-----

Apache2 configuration II
=========================

VirtualHost configuration for both **FastCGI** and **CGI**

.. code:: bash

    <VirtualHost *:81>
        
        # [ ... ] Standard config goes here

        # Longer timeout for WPS... default = 40
        FcgidIOTimeout 120
        FcgidInitialEnv LC_ALL "en_US.UTF-8"
        FcgidInitialEnv LANG "en_US.UTF-8"
        FcgidInitialEnv PYTHONIOENCODING UTF-8
        FcgidInitialEnv QGIS_DEBUG 1
        FcgidInitialEnv QGIS_SERVER_LOG_FILE "QGIS_SERVER_DIR/logs/qgis-apache-001.log"
        FcgidInitialEnv QGIS_SERVER_LOG_LEVEL 0
        FcgidInitialEnv QGIS_PLUGINPATH "QGIS_SERVER_DIR/plugins"
        FcgidInitialEnv QGIS_AUTH_DB_DIR_PATH "QGIS_SERVER_DIR"
        FcgidInitialEnv QGIS_OPTIONS_PATH "QGIS_SERVER_DIR"
        FcgidInitialEnv QGIS_CUSTOM_CONFIG_PATH "QGIS_SERVER_DIR"
        FcgidInitialEnv DISPLAY ":99"

-----

Apache2 configuration IV
=========================

**CGI**

.. code:: bash

        # For simple CGI: ignored by fcgid
        SetEnv LC_ALL "en_US.UTF-8"
        SetEnv LANG "en_US.UTF-8"
        SetEnv PYTHONIOENCODING UTF-8
        SetEnv QGIS_DEBUG 1
        SetEnv QGIS_SERVER_LOG_FILE "QGIS_SERVER_DIR/logs/qgis-apache-001.log"
        SetEnv QGIS_SERVER_LOG_LEVEL 0
        SetEnv QGIS_PLUGINPATH "QGIS_SERVER_DIR/plugins"
        SetEnv QGIS_AUTH_DB_DIR_PATH "QGIS_SERVER_DIR"
        SetEnv QGIS_OPTIONS_PATH "QGIS_SERVER_DIR"
        SetEnv QGIS_CUSTOM_CONFIG_PATH "QGIS_SERVER_DIR"
        SetEnv DISPLAY ":99"

----

Apache2 configuration V
=========================

.. code:: bash

        # Needed for QGIS HelloServer plugin HTTP BASIC auth
        <IfModule mod_fcgid.c>
            RewriteEngine on
            RewriteCond %{HTTP:Authorization} .
            RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        </IfModule>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
            AllowOverride All
            Options +ExecCGI -MultiViews +FollowSymLinks
            Allow from all
            AddHandler cgi-script .cgi
            AddHandler fcgid-script .fcgi
            Require all granted        
        </Directory>

    </VirtualHost>
        
-----

Apache2 configuration VI
=========================

Enable sites and restart

.. code:: bash

    a2enmod rewrite # Only required by some plugins
    a2enmod cgid # Required by plain old CGI
    a2dissite 000-default 
    a2ensite 001-qgis-server

    # Listen on port 81 instead of 80 (nginx)
    sed -i -e 's/Listen 80/Listen 81/' /etc/apache2/ports.conf
   
    service apache2 restart # Restart the server


**Checkpoint**: check wether Apache is listening on localhost port 8081 http://localhost:8081

----

Nginx Installation
===================

.. code:: bash

    # Install the software
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install nginx uwsgi

----

Nginx configuration I
=======================

.. code:: bash

    rm /etc/nginx/sites-enabled/default
    cp /vagrant/resources/nginx/qgis-server \
        /etc/nginx/sites-enabled
    sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@" \
        /etc/nginx/sites-enabled/qgis-server

----

Nginx configuration II
=======================

.. code:: php

    # Extract server name and port from HTTP_HOST, this 
    # is needed because we are behind a VMs mapped port

    map $http_host $parsed_server_name {
        default  $host;
        "~(?P<h>[^:]+):(?P<p>.*+)" $h;
    }

    map $http_host $parsed_server_port {
        default  $host;
        "~(?P<h>[^:]+):(?P<p>.*+)" $p;
    }

----

Nginx configuration III
=======================

.. code:: php

    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root QGIS_SERVER_DIR/htdocs;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

----

Nginx configuration IV
=======================

.. code:: php

        location /cgi-bin/ { 
            # Disable gzip (it makes scripts feel slower since they 
            # have to complete before getting gzipped)
            gzip off;

            # Fastcgi socket
            fastcgi_pass  unix:/tmp/qgis-server.sock;

            # $http_host contains the original server name and port, 
            # such as: "localhost:8080"
            # QGIS Server behind a VM needs this parsed values in 
            # order to automatically get the correct values for the 
            # online resource URIs
            fastcgi_param SERVER_NAME       $parsed_server_name;
            fastcgi_param SERVER_PORT       $parsed_server_port;

            # Fastcgi parameters, include the standard ones
            include /etc/nginx/fastcgi_params;

        }
    }


----

Nginx configuration V
=======================


.. code:: bash

    # Restart the server
    /etc/init.d/nginx restart


**Checkpoint**: check wether Nginx is listening on localhost port 8080 http://localhost:8080

----

Uvsgi configuration I
=======================

.. code:: bash

    # Configure uwsgi
    cp /vagrant/resources/uwsgi/uwsgi-qgis.service \
        /etc/systemd/system/uwsgi-qgis.service
    cp /vagrant/resources/uwsgi/qgis-server.ini \
        /etc/uwsgi/apps-enabled/qgis-server.ini
    sed -i -e "s@QGIS_SERVER_DIR@${QGIS_SERVER_DIR}@" \
        /etc/uwsgi/apps-enabled/qgis-server.ini

----

Uvsgi configuration II
=======================

Service `systemd` configuration

.. code:: ini

    [Unit]
    Description=Starts QGIS Server as FastCGI uwsgi app
    After=network.target

    [Service]
    ExecStart=/usr/bin/uwsgi --ini \
        /etc/uwsgi/apps-enabled/qgis-server.ini
    User=www-data
    Group=www-data

----

Uvsgi configuration II
=======================

.. code:: ini

    Restart=on-failure
    KillSignal=SIGQUIT
    Type=notify
    StandardError=syslog
    NotifyAccess=all

    [Install]
    WantedBy=multi-user.target

----

Uvsgi configuration III
=======================

App configuration

.. code:: ini

    [uwsgi]
    fastcgi-socket = /tmp/qgis-server.sock
    protocol = fastcgi
    worker-exec = /usr/lib/cgi-bin/qgis_mapserv.fcgi
    processes = 10
    enable-threads = true
    master = true
    chdir = /usr/lib/cgi-bin/
    chmod-socket = 777
    vacuum = true
    logto = QGIS_SERVER_DIR/logs/qgis-nginx-000.log

----

Uvsgi configuration IV
=======================

.. code:: ini

    uid = www-data
    gid = www-data

    env = QGIS_AUTH_DB_DIR_PATH=QGIS_SERVER_DIR/projects
    env = QGIS_SERVER_LOG_FILE=QGIS_SERVER_DIR/logs/qgis-nginx-000.log
    env = QGIS_SERVER_LOG_LEVEL=0
    env = QGIS_DEBUG=1
    env = DISPLAY=:99
    env = QGIS_PLUGINPATH=QGIS_SERVER_DIR/plugins
    env = QGIS_OPTIONS_PATH=QGIS_SERVER_DIR
    env = QGIS_CUSTOM_CONFIG_PATH=QGIS_SERVER_DIR

----

Uvsgi configuration V
=======================

Restart the service

.. code:: bash

    update-rc.d uwsgi remove # Remove stock uwsgi
    systemctl enable /etc/systemd/system/uwsgi-qgis.service
    service uwsgi-qgis start

----

Checkpoint: Apache2
===========================

Check **WMS** on localhost 8081 in the browser

http://localhost:8081

Follow the links!


----

Checkpoint: Nginx
===========================

Check **WMS** on localhost 8080 in the browser

http://localhost:8080

Follow the links!

----

Checkpoint: QGIS as a Client
===================================

Check **WMS** and **WFS** using QGIS as a client.

Check that **WFS** requires a "username" and "password"

Check that **WWS** *GetFeatureInfo* returns a (blueish) formatted HTML

Note: a test project with pre-configured endpoints 
is available in the same directory that hosts
this presentation.

----

Checkpoint: WMS search
=================================

Searching features with **WMS**

http://localhost:8080/cgi-bin/qgis_mapserv.fcgi?MAP=/qgis-server/projects/helloworld.qgs&SERVICE=WMS&REQUEST=GetFeatureInfo&LAYERS=world&QUERY_LAYERS=world&FILTER=world%3A%22NAME%22%20%3D%20%27SPAIN%27

The filter is a QGIS Expression:

**FILTER=world:"NAME" = 'SPAIN'**

* Field name is enclosed in double quotes, literal string in single quotes
* You need one space between the operator and tokens
* Temporary fix: you need BBOX (fixed in master)


----

Checkpoint: highlighting
=================================

The **SELECTION** parameter can highlight features from one or more layers:
Vector features can be selected by passing comma separated lists with feature ids in *GetMap* and *GetPrint*.
Example: *SELECTION=mylayer1:3,6,9;mylayer2:1,5,6*

http://localhost:8080/cgi-bin/qgis_mapserv.fcgi?MAP=/qgis-server/projects/helloworld.qgs&SERVICE=WMS&VERSION=1.3.0&SELECTION=world%3A44&REQUEST=GetMap&FORMAT=image%2Fpng&TRANSPARENT=true&LAYERS=world&CRS=EPSG%3A4326&STYLES=&DPI=180&WIDTH=1794&HEIGHT=1194&BBOX=31.79443359375%2C-18.21533203125%2C58.02978515625%2C21.20361328125


----

Checkpoint: printing
==============================

From composer templates (with substitutions!)

.. code:: xml

  <ComposerTemplates>
   <ComposerTemplate width="297" height="210" name="Printable World">
    <ComposerMap width="283.208" height="176" name="map0"/>
   </ComposerTemplate>
  </ComposerTemplates>

FORMAT can be any of PDF, JPG, PNG
See also: DXF Export

----

Checkpoint: printing URL
==============================

http://localhost:8080/cgi-bin/qgis_mapserv.fcgi?MAP=/qgis-server/projects/helloworld.qgs&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetPrint&TEMPLATE=Printable%20World&CRS=EPSG%3A4326&map0:EXTENT=4,52,14,58&FORMAT=jpg&LAYERS=bluemarble,world

----

Checkpoint: printing substitutions
===================================

- Assign an *ID* to the label
- add *label_name=Your custom text*
- as an ID, choose a word that is not reserved in **WMS**

http://localhost:8080/cgi-bin/qgis_mapserv.fcgi?MAP=/qgis-server/projects/helloworld.qgs&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetPrint&TEMPLATE=Printable%20World&CRS=EPSG%3A4326&map0:EXTENT=4,52,14,58&FORMAT=jpg&LAYERS=bluemarble,world&print_title=My%20Custom%20Title!

----

QGIS Server 2.x and python
============================

Since QGIS 2.8

.. code:: python

    from qgis.server import QgsServer   
    s = QgsServer()
    header, body = s.handleRequest(
        'MAP=/qgis-server/projects/helloworld.qgs' + 
        '&SERVICE=WMS&REQUEST=GetCapabilities')
    print(header, body)

Full script:
https://github.com/qgis/QGIS/blob/release-2_18/tests/src/python/qgis_wrapped_server.py

----

QGIS Server 3.x and python
============================

Since QGIS 2.99

.. code:: python

    from qgis.core import QgsApplication
    from qgis.server import *
    qgs_app = QgsApplication([], False)
    qgs_server = QgsServer()
    request = QgsBufferServerRequest(
        'MAP=/qgis-server/projects/helloworld.qgs' + 
        '&SERVICE=WMS&REQUEST=GetCapabilities')
    response = QgsBufferServerResponse()
    qgs_server.handleRequest(request, response)
    print(response.headers(), response.body())
    qgs_app.exitQgis()

Full script:
https://github.com/qgis/QGIS/blob/master/tests/src/python/qgis_wrapped_server.py
