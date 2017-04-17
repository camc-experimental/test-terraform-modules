#!/bin/bash
#################################################################
# Script to install MongoDB, NodeJS, AngularJS and StrongLoop 
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

LOGFILE="/var/log/install_mongodb_strongloop_angular_nodejs.log"

SAMPLE_URL=$1

#update

echo "---update system---" | tee -a $LOGFILE 2>&1 
yum update -y >> $LOGFILE 2>&1 

#install mongodb

echo "---start installing mongodb---" | tee -a $LOGFILE 2>&1
MONGO_REPO=/etc/yum.repos.d/mongodb-org-3.4.repo
cat <<EOT | tee -a $MONGO_REPO                                                     >> $LOGFILE 2>&1 || { echo "---Failed to create mongo repo---" | tee -a $LOGFILE; exit 1; }
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOT
yum install -y mongodb-org                                                         >> $LOGFILE 2>&1 || { echo "---Failed to install mongodb-org---" | tee -a $LOGFILE; exit 1; }
service mongod start                                                               >> $LOGFILE 2>&1 || { echo "---Failed to start mongodb---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing mongodb---" | tee -a $LOGFILE 2>&1


#install node.js

echo "---start installing node.js---" | tee -a $LOGFILE 2>&1 
yum install epel-release -y                                                        >> $LOGFILE 2>&1 || { echo "---Failed to install epel---" | tee -a $LOGFILE; exit 1; }
yum install nodejs -y                                                              >> $LOGFILE 2>&1 || { echo "---Failed to install node.js---"| tee -a $LOGFILE; exit 1; }
echo "---finish installing node.js---" | tee -a $LOGFILE 2>&1 


#install angularjs

echo "---start installing angularjs---" | tee -a $LOGFILE 2>&1 
npm install -g grunt-cli bower yo generator-karma generator-angular                >> $LOGFILE 2>&1 || { echo "---Failed to install angular tools---" | tee -a $LOGFILE; exit 1; }
yum install gcc ruby ruby-devel rubygems -y                                        >> $LOGFILE 2>&1 || { echo "---Failed to install ruby---" | tee -a $LOGFILE; exit 1; }
gem install compass                                                                >> $LOGFILE 2>&1 || { echo "---Failed to install compass---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing angularjs---" | tee -a $LOGFILE 2>&1 

#install strongloop

echo "---start installing strongloop---" | tee -a $LOGFILE 2>&1 
yum groupinstall 'Development Tools' -y                                            >> $LOGFILE 2>&1 || { echo "---Failed to install development tools---" | tee -a $LOGFILE; exit 1; }
npm install -g strongloop                                                          >> $LOGFILE 2>&1 || { echo "---Failed to install strongloop---" | tee -a $LOGFILE; exit 1; }
echo "---finish installing strongloop---" | tee -a $LOGFILE 2>&1 


#install sample application

echo "---start installing sample application---" | tee -a $LOGFILE 2>&1 
		
#create mongodb user
dbUserPwd=$(date | md5sum | head -c 10)
mongo admin --eval "db.createUser({user: \"sampleUser\", pwd: \"$dbUserPwd\", roles: [{role: \"userAdminAnyDatabase\", db: \"admin\"}]})"    >> $LOGFILE 2>&1 || { echo "---Failed to create MongoDB user---" | tee -a $LOGFILE; exit 1; }
		
#download and untar application
yum install curl -y                                                                                                                          >> $LOGFILE 2>&1 || { echo "---Failed to install curl---" | tee -a $LOGFILE; exit 1; }
SAMPLE_DIR=/root/sample
mkdir $SAMPLE_DIR                                                                                                                            
curl -k -o sample.tar.gz $SAMPLE_URL                                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to download application tarball---" | tee -a $LOGFILE; exit 1; }
tar -xzvf sample.tar.gz -C $SAMPLE_DIR                                                                                                       >> $LOGFILE 2>&1 || { echo "---Failed to untar the application---" | tee -a $LOGFILE; exit 1; }

#start application
sed -i -e "s/sampleUserPwd/$dbUserPwd/g" $SAMPLE_DIR/server/datasources.json                                                                 >> $LOGFILE 2>&1 || { echo "---Failed to configure datasource with mongo user password---" | tee -a $LOGFILE; exit 1; } 

#make sample application as a service
SAMPLE_APP_SERVICE_CONF=/etc/systemd/system/nodeserver.service
cat <<EOT | tee -a $SAMPLE_APP_SERVICE_CONF                                                                                                  >> $LOGFILE 2>&1 || { echo "---Failed to config the sample node service---" | tee -a $LOGFILE; exit 1; }
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
systemctl enable nodeserver.service                                                                                                         >> $LOGFILE 2>&1 || { echo "---Failed to enable the sample node service---" | tee -a $LOGFILE; exit 1; }
systemctl start nodeserver.service                                                                                                          >> $LOGFILE 2>&1 || { echo "---Failed to start the sample node service---" | tee -a $LOGFILE; exit 1; }
		
echo "---finish installing sample application---" | tee -a $LOGFILE 2>&1 		


