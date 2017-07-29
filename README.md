# QGIS Server 2.x Vagrant testing VMs with Apache and Nginx

Yet another QGIS Server demo VM, prepared for Nødebo QGIS 
confererence and workshop 2017.


## Requirements

You need a working installation of Vagrant with Virtualbox.

Please follow the installation instructions here:

https://www.vagrantup.com/docs/installation/
https://www.virtualbox.org/wiki/Downloads

## Features

This machine is based on xenial and comes with a sample project and a few plugins.


| Server     | Port       | Mapped to |
|---         |---         |---        |
| Nginx      | 80         | 8080      |
| Apache     | 81         | 8081      |


### Apache2 stack

- Apache2
- FastCGI with mod_fcgid
- CGI with mod_cgid

### Nginx stack

- nginx
- uwsgi

### Plugins

- HTTP Basic Auth (for WFS protection)
- GetFeatureInfo HTML formatter
- Simple Browser

## Documentation

A presentation is available in the [docs directory](docs/index.rst)

## Setup

From the directory that contains this README:

```
vagrant up --no-provision
```

Follow the steps in the documentation for further setup.



