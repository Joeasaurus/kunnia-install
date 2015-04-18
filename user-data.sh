#!/bin/bash

yum -y install git
git clone https://github.com/Joeasaurus/kunnia-install.git /tmp/install
cd /tmp/install
chmod +x run.sh
./run.sh