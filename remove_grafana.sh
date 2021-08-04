#!/usr/bin/env bash

# manual Grafana removal for WLANPi RPi edition

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

GRAFANA_PORT=4000

echo ""
echo "* ========================="
echo "* Removing Grafana..."
echo "* ========================="


echo "* Stopping services."
sudo systemctl stop grafana-server
sudo systemctl disable grafana-server

echo "* Removing packages & files."
sudo apt-get purge grafana -y
sudo rm -rf /etc/grafana
sudo rm -rf /var/lib/grafana
sudo rm -rf /var/log/grafana
sudo rm -rf /usr/share/grafana

echo "* Restoring firewall port."
sudo ufw deny $GRAFANA_PORT

echo "* Done."


echo ""
echo "* ========================="
echo "* Removing Influxdb..."
echo "* ========================="

sudo systemctl stop influxdb
sudo systemctl disable influxdb
sudo apt-get purge influxdb -y
sudo rm -rf /var/lib/influxdb
sudo rm /etc/default/influxdb

echo "* Removing cron job."
crontab -l | grep -v 'get_stats.sh'  | crontab -

# tidy up grafana binaries downloaded
sudo rm grafana*.deb*

echo "* Done."