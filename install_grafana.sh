#!/usr/bin/env bash

# manual Grafana installation for WLANPi RPi edition

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

set -e

source .env

echo ""
echo "* ========================="
echo "* Installing Grafana..."
echo "* ========================="


echo "* Installing pre-req packages."
sudo apt-get install -y adduser libfontconfig1

echo "* Downloading Grafana."
wget https://dl.grafana.com/oss/release/grafana_8.0.5_armhf.deb

echo "* Installing Grafana."
sudo dpkg -i grafana_8.0.5_armhf.deb

# remove requirement to set default admin pwd & change default user/pwd to wlanpi/wlanpi
echo "* Customizing Grafana."
sudo sed -i 's/;disable_initial_admin_creation/disable_initial_admin_creation/g' /etc/grafana/grafana.ini
sudo sed -i 's/;admin_user = admin/admin_user = '"$GRAFANA_USER"'/g' /etc/grafana/grafana.ini
sudo sed -i 's/;admin_password = admin/admin_password = '"$GRAFANA_PWD"'/g' /etc/grafana/grafana.ini

# set grafana to listen on port GRAFANA_PORT
sudo sed -i 's/;http_port = 3000/http_port = '"$GRAFANA_PORT"'/g' /etc/grafana/grafana.ini

# open port on ufw firewall
echo "* Opening FW port for Grafana."
sudo ufw allow ${GRAFANA_PORT}

# take care of grafana service
echo "* Enabling & starting Grafana service."
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# display status of service
echo "* Grafana service status:"
sudo systemctl status --no-pager -l grafana-server | head -n 10
echo "* Grafana Done."


echo ""
echo "* ========================="
echo "* Installing InfluxDB..."
echo "* ========================="


echo "* Getting InfluxDB code...."

sudo wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt update

echo "* Installing InfluxDB code...."
sudo apt install influxdb
sudo chown influxdb:influxdb /usr/lib/influxdb/scripts/influxd-systemd-start.sh

echo "* Enabling & starting InfluxDB service."
sudo systemctl unmask influxdb.service
sudo systemctl enable influxdb
sudo systemctl start influxdb

# display status of service
echo "* InfluxDB service status:"
sudo systemctl status --no-pager -l influxdb | head -n 10

echo ""
echo "* ========================="
echo "* Configuring InfluxDB..."
echo "* ========================="

echo "* Creating DB & users..."
influx -execute "create database wlanpi" 
influx -execute "create retention policy wiperf_30_days on wlanpi duration 30d replication 1" -database wlanpi
influx -execute "create user $DB_USER with password '$DB_PWD' with all privileges" -database wlanpi


sudo sed -i 's/# auth-enabled = false/auth-enabled = true/g' /etc/influxdb/influxdb.conf
sudo systemctl restart influxdb

# add data source to Grafana
echo "* Adding DB as data source to Grafana..."
sudo cp influx_datasource.yaml /etc/grafana/provisioning/datasources/
sudo systemctl restart grafana-server

# add dashboard to Grafana
echo "* Adding dashboard to Grafana..."
sudo cp  dashboard/WLAN_Pi_Monitor.json /usr/share/grafana/public/dashboards/
sudo cp import_dashboard.yaml /etc/grafana/provisioning/dashboards/
sudo systemctl restart grafana-server

# set crontab 
echo "* adding crontab job to start polling..."
if crontab -u wlanpi -l &>/dev/null; then
  # Keep existing cron jobs and add ours
  { crontab -u wlanpi -l 2>/dev/null; echo "*/1 * * * * /home/wlanpi/wlanpi_monitor/get_stats.sh"; } | crontab -u wlanpi -
else 
  # There are no existing cron jobs, let's add our job as the very first one
  echo "*/1 * * * * /home/wlanpi/wlanpi_monitor/get_stats.sh" | crontab -u wlanpi -
fi
echo "All cron jobs of user \"wlanpi\" after we've finished:"
crontab -u wlanpi -l
echo "* Done."

echo ""
echo "* ================================================"
echo "* Browse Grafana at: http://$(hostname -I | xargs):${GRAFANA_PORT}/ (user/pwd=$GRAFANA_USER/$GRAFANA_PWD)"
echo "* ================================================"
echo ""
echo ""
