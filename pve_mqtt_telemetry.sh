# Сборщик аппаратных метрик Proxmox VE для Home Assistant
#!/bin/bash
MQTT_HOST="192.168.1.174"
MQTT_USER="pve_agent"
MQTT_PASS="password"

# Отправка Discovery payload для автоматической регистрации в HA
mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -t "homeassistant/sensor/pve/temp_sdc/config" -m "{\"name\": \"Disk Array Temp\", \"stat_t\": \"pve/status/temp_sdc\", \"unit_of_meas\": \"°C\", \"dev_cla\": \"temperature\"}" -r

while true; do
  # Сбор SMART-телеметрии HDD
  TEMP=$(smartctl -A /dev/sdc | grep Temperature_Celsius | awk '{print $10}')
  
  # Сбор метрик заполненности пула MergerFS
  USAGE=$(df /mnt/media_pool | tail -1 | awk '{print $5}' | tr -d '%')
  
  mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -t "pve/status/temp_sdc" -m "$TEMP"
  mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -t "pve/status/usage_pool" -m "$USAGE"
  sleep 60
done
