#!/bin/bash
#################################################################
# Script to install NodeJS and StrongLoop 
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

LOGFILE="/var/log/install_strongloop_nodejs.log"

SAMPLE_URL=$1
MongoDB_Server=$2
DBUserPwd=$3
UseSystemCtl=$4

#update

echo "---update system---" | tee -a $LOGFILE 2>&1 
yum update -y >> $LOGFILE 2>&1 

#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
yum install epel-release -y                                        >> $LOGFILE 2>&1 || { echo "---Failed to install epel---" | tee -a $LOGFILE; exit 1; }
yum install nodejs -y                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 

#install strongloop

echo "---start installing strongloop---" | tee -a $LOGFILE 2>&1 
yum groupinstall 'Development Tools' -y                            >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
npm install -g strongloop                                          >> $LOGFILE 2>&1 || { echo "---Failed to install strongloop---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing strongloop---" | tee -a $LOGFILE 2>&1 

#install sample application

echo "---start installing sample application---" | tee -a $LOGFILE 2>&1 

#download and untar application
yum install curl -y                                                                    >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
SAMPLE_DIR=/root/sample
mkdir $SAMPLE_DIR                                                                                                                            
curl -k -o sample.tar.gz $SAMPLE_URL                                                   >> $LOGFILE 2>&1 || { echo "---Failed to download application tarball---" | tee -a $LOGFILE; exit 1; }
tar -xzvf sample.tar.gz -C $SAMPLE_DIR                                                 >> $LOGFILE 2>&1 || { echo "---Failed to untar the application---" | tee -a $LOGFILE; exit 1; }

#start application
sed -i -e "s/mongodb-server/$MongoDB_Server/g" $SAMPLE_DIR/server/datasources.json     >> $LOGFILE 2>&1 || { echo "---Failed to configure datasource with mongodb server address---" | tee -a $LOGFILE; exit 1; }
sed -i -e "s/sampleUserPwd/$DBUserPwd/g" $SAMPLE_DIR/server/datasources.json           >> $LOGFILE 2>&1 || { echo "---Failed to configure datasource with mongo user password---" | tee -a $LOGFILE; exit 1; } 

#make sample application as a service
if [ "$UseSystemCtl" == "true" ]; then
    SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
    cat <<EOT | tee -a $SAMPLE_APP_SERVICE_CONF                                            >> $LOGFILE 2>&1 || { echo "---Failed to config the sample node service---" | tee -a $LOGFILE; exit 1; }
[Unit]
Description=Node.js Example Server

[Service]
ExecStart=/usr/bin/node $SAMPLE_DIR/server/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=3000

[Install]
WantedBy=multi-user.target
EOT
    systemctl enable nodeserver.service                                                    >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
    systemctl start nodeserver.service                                                     >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }
else
	slc run $SAMPLE_DIR &                                                                  >> $LOGFILE 2>&1 || { echo "---Failed to start the application---" | tee -a $LOGFILE; exit 1; }
fi
		
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		

