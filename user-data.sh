#!/bin/bash

yum -y install git wget unzip
rm -rf /tmp/install
git clone https://github.com/Joeasaurus/kunnia-install.git /tmp/install
cd /tmp/install
chmod +x run.sh
./run.sh > /var/log/kunnia-install.log 2>&1
