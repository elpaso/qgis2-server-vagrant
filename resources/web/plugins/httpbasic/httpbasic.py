import os

from qgis.server import *
from qgis.core import QgsMessageLog
import base64

class HTTPBasicFilter(QgsServerFilter):

        def responseComplete(self):
            request = self.serverInterface().requestHandler()
            params = request.parameterMap( )
            if params.get('SERVICE').upper() != 'WFS':
                return
            if self.serverInterface().getEnv('HTTP_AUTHORIZATION'):
                username, password = base64.b64decode(self.serverInterface().getEnv('HTTP_AUTHORIZATION')[6:]).split(':')                
                if (username == os.environ.get('QGIS_SERVER_USERNAME', 'username')
                        and password == os.environ.get('QGIS_SERVER_PASSWORD', 'password')):
                    QgsMessageLog.logMessage("Wrong username and password: %s %s" % (username, password), "server")
                    return
            # No auth ...
            request.clearHeaders()
            request.setHeader('Status', '401 Authorization required')
            request.setHeader('WWW-Authenticate', 'Basic realm="QGIS Server"')
            request.clearBody()
            request.appendBody('<h1>Authorization required</h1>')

class HTTPBasic:

    def __init__(self, serverIface):
        # Save reference to the QGIS server interface
        serverIface.registerFilter( HTTPBasicFilter(serverIface), 100 )
    
