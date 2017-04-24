#!/bin/bash
#####################################################################
# Script to install NodeJS, Angular, Express and sample application
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
#####################################################################

set -o errexit
set -o nounset
set -o pipefail

LOGFILE="/var/log/install_publick_key.log"

TEMP_SSH_KEY=${variable_1}
SSH_USER=${variable_2}

echo "---Add customer public key for ssh---" | tee -a $LOGFILE 2>&1
echo $TEMP_SSH_KEY | tee -a $SSH_USER/.ssh/authorized_keys                                                        >> $LOGFILE 2>&1 || { echo "---Failed to add customer public key for ssh---" | tee -a $LOGFILE; exit 1; }

