#!/bin/bash

SOLANA_DIR=/root/solana

echo "\033[0;32mInstalling monitoring...\033[0m"
curl -s https://repos.influxdata.com/influxdata-archive_compat.key > influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
apt-get update
apt-get -y install telegraf jq bc
adduser telegraf sudo
adduser telegraf adm
echo "telegraf ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.orig
rm -rf /etc/telegraf/telegraf.conf
cd $SOLANA_DIR && git clone https://github.com/stakeconomy/solanamonitoring/
chmod +x $SOLANA_DIR/solanamonitoring/monitor.sh
echo -e "\033[0;32mEnter Validator name:\033[0m"
read VALIDATOR_NAME </dev/tty
touch /etc/telegraf/telegraf.conf
cat > /etc/telegraf/telegraf.conf <<EOF
# Global Agent Configuration
[agent]
  hostname = "$VALIDATOR_NAME" # set this to a name you want to identify your node in the grafana dashboard
  flush_interval = "15s"
  interval = "15s"
# Input Plugins
[[inputs.cpu]]
    percpu = true
    totalcpu = true
    collect_cpu_time = false
    report_active = false
[[inputs.disk]]
    ignore_fs = ["devtmpfs", "devfs"]
[[inputs.mem]]
[[inputs.net]]
[[inputs.system]]
[[inputs.swap]]
[[inputs.netstat]]
[[inputs.processes]]
[[inputs.kernel]]
[[inputs.diskio]]
# Output Plugin InfluxDB
[[outputs.influxdb]]
  database = "metricsdb"
  urls = [ "http://metrics.stakeconomy.com:8086" ] # keep this to send all your metrics to the community dashboard otherwise use http://yourownmonitoringnode:8086
  username = "metrics" # keep both values if you use the community dashboard
  password = "password"
[[inputs.exec]]
  commands = ["sudo su -c $SOLANA_DIR/solanamonitoring/monitor.sh -s /bin/bash root"] # change home and username to the useraccount your validator runs at
  interval = "3m"
  timeout = "1m"
  data_format = "influx"
  data_type = "integer"
EOF

systemctl daemon-reload
sudo systemctl enable telegraf


systemctl start telegraf
echo "### Install is complete."

# bash <(wget -qO- http://51.75.161.136/telegraf_install/)
