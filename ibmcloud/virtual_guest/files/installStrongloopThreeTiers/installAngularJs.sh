#!/bin/bash
#################################################################
# Script to install NodeJS and AngularJS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_angular_nodejs.log"

SAMPLE_URL=$1
STRONGLOOP_SERVER=$2
SAMPLE_APP_PORT=$3
UseSystemCtl=$4

#update

echo "---update system---" | tee -a $LOGFILE 2>&1 
yum update -y >> $LOGFILE 2>&1 

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
yum install epel-release -y                                                >> $LOGFILE 2>&1 || { echo "---Failed to install epel---" | tee -a $LOGFILE; exit 1; }
yum install nodejs -y                                                      >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 

#install angularjs

echo "---start installing angularjs---" | tee -a $LOGFILE 2>&1 
npm install -g grunt-cli bower yo generator-karma generator-angular        >> $LOGFILE 2>&1 || { echo "---Failed to install angular tools---" | tee -a $LOGFILE; exit 1; }
yum install gcc ruby ruby-devel rubygems make -y                           >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
gem install compass                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install compass---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing angularjs---" | tee -a $LOGFILE 2>&1 

#install sample application

echo "---start installing sample application---" | tee -a $LOGFILE 2>&1 

#download and untar application
yum install curl -y                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
SAMPLE_DIR=/root/sample
mkdir $SAMPLE_DIR                                                                                                                            
curl -k -o sample.tar.gz $SAMPLE_URL                                       >> $LOGFILE 2>&1 || { echo "---Failed to download application tarball---" | tee -a $LOGFILE; exit 1; }
tar -xzvf sample.tar.gz -C $SAMPLE_DIR                                     >> $LOGFILE 2>&1 || { echo "---Failed to untar the application---" | tee -a $LOGFILE; exit 1; }

#start application
sed -i -e "s/strongloop-server/$STRONGLOOP_SERVER/g" $SAMPLE_DIR/server/server.js      >> $LOGFILE 2>&1 || { echo "---Failed to configure server.js---" | tee -a $LOGFILE; exit 1; } 
sed -i -e "s/8080/$SAMPLE_APP_PORT/g" $SAMPLE_DIR/server/server.js                     >> $LOGFILE 2>&1 || { echo "---Failed to change listening port in server.js---" | tee -a $LOGFILE; exit 1; } 

#make sample application as a service
if [ "$UseSystemCtl" == "true" ]; then
    SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
    cat <<EOT | tee -a $SAMPLE_APP_SERVICE_CONF                                >> $LOGFILE 2>&1 || { echo "---Failed to config the sample node service---" | tee -a $LOGFILE; exit 1; }
[Unit]
Description=Node.js Example Server

[Service]
ExecStart=/usr/bin/node $SAMPLE_DIR/server/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=$SAMPLE_APP_PORT

[Install]
WantedBy=multi-user.target
EOT
    systemctl enable nodeserver.service                                       >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
    systemctl start nodeserver.service                                        >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }
else
	node $SAMPLE_DIR/server/server.js &                                       >> $LOGFILE 2>&1 || { echo "---Failed to start the application---" | tee -a $LOGFILE; exit 1; }
fi

echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		
