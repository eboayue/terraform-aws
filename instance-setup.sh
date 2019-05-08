#!/bin/bash
sudo apt-get -y update
sudo apt-get -y install ruby
sudo apt-get -y install wget
sudo apt-get -y install nginx
sudo service nginx start
sudo apt -y install awscli
cd /var/www/html/
sudo aws s3 cp s3://twitchlogo/Twitch_logo.jpg .
sudo sed -i '14 a <img src="TwitchLogo.png" alt="Twitch.tv Logo">' index.nginx-debian.html
