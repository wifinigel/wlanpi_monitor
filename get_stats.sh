#!/usr/bin/env bash

DB_USER=wlanpi
DB_PWD=wlanpi_1963

TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMP=$((TEMP / 1000))
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_temp,host=wlanpi value=${TEMP}"

CPU=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_cpu,host=wlanpi value=${CPU}"

MEM=$(free -m | awk 'NR==2{printf "%s %s %.2f", $3,$2,$3*100/$2 }')
MEM_USED_MB=$(echo $MEM | cut -d " " -f 1)
MEM_TOTAL_MB=$(echo $MEM | cut -d " " -f 2)
MEM_USED_PERCENT=$(echo $MEM | cut -d " " -f 3)

curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_mem_used_mb,host=wlanpi value=${MEM_USED_MB}"
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_mem_total_mb,host=wlanpi value=${MEM_TOTAL_MB}"
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_mem_used_percent,host=wlanpi value=${MEM_USED_PERCENT}"

DISK=$(df -h | awk '$NF=="/"{printf "%d %d %d", $3,$2,$5}')
DISK_USED_GB=$(echo $DISK | cut -d " " -f 1)
DISK_TOTAL_GB=$(echo $DISK | cut -d " " -f 2)
DISK_USED_PERCENT=$(echo $DISK | cut -d " " -f 3)

curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_disk_used_gb,host=wlanpi value=${DISK_USED_GB}"
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_disk_total_gb,host=wlanpi value=${DISK_TOTAL_GB}"
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_disk_used_percent,host=wlanpi value=${DISK_USED_PERCENT}"

CPU_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
VOLTAGE=$(/opt/vc/bin/vcgencmd measure_volts | cut -d "=" -f 2  | sed 's/.$//')

curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_cpu_freq,host=wlanpi value=${CPU_FREQ}"
curl -u $DB_USER:$DB_PWD -XPOST 'http://localhost:8086/write?db=wlanpi' --data-binary "wlanpi_voltage,host=wlanpi value=${VOLTAGE}"
