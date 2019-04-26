#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install ruby
sudo apt-get -y install wget
sudo apt-get -y install nginx
sudo service nginx start
cd /home/ubuntu
wget https://bucket-name.s3.amazonaws.com/latest/install
chmod u+x ./install
sudo ./install auto