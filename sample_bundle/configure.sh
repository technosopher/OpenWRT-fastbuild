#!/bin/bash
cd $TEMP_DIR
echo "./configure is being run in `pwd`" 
git clone https://github.com/opentechinstitute/commotion-router.git
cd commotion-router
SRC_DIR="`pwd`/openwrt"
./setup.sh

