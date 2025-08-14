#!/bin/sh

# Create config directory for mounting
mkdir -p /config

# Copy original config.json to /config directory if not exists
if [ ! -f /config/config.json ]; then
  cp /config.json /config/config.json
fi

if [ -f /config/config_info.txt ]; then
  echo "config.json exist"
else
  IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  if [ -z "$UUID" ]; then
    echo "UUID is not set, generate random UUID "
    UUID="$(/xray uuid)"
    echo "UUID: $UUID"
  fi

  if [ -z "$XHTTP_PATH" ]; then
    echo "XHTTP_PATH is not set, generate random XHTTP_PATH "
    PATH_LENGTH="$(( RANDOM % 4 + 8 ))"
    XHTTP_PATH="/""$(/xray uuid | tr -d '-' | cut -c 1-$PATH_LENGTH)"
    echo "XHTTP_PATH: $XHTTP_PATH"
  fi

  if [ -z "$EXTERNAL_PORT" ]; then
    echo "EXTERNAL_PORT is not set, use default value 443"
    EXTERNAL_PORT=443
  fi

  if [ -n "$HOSTMODE_PORT" ];then
    EXTERNAL_PORT=$HOSTMODE_PORT
    jq ".inbounds[1].port=$HOSTMODE_PORT" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json
  fi

  if [ -z "$DEST" ]; then
    echo "DEST is not set. default value www.apple.com:443"
    DEST="www.apple.com:443"
  fi

  if [ -z "$SERVERNAMES" ]; then
    echo "SERVERNAMES is not set. use default value [\"www.apple.com\",\"images.apple.com\"]"
    SERVERNAMES="www.apple.com images.apple.com"
  fi

  if [ -z "$PRIVATEKEY" ]; then
    echo "PRIVATEKEY is not set. generate new key"
    /xray x25519 >/key
    PRIVATEKEY=$(cat /key | grep "Private" | awk -F ': ' '{print $2}')
    PUBLICKEY=$(cat /key | grep "Public" | awk -F ': ' '{print $2}')
    echo "Private key: $PRIVATEKEY"
    echo "Public key: $PUBLICKEY"
  fi

  if [ -z "$NETWORK" ]; then
    echo "NETWORK is not set,set default value xhttp"
    NETWORK="xhttp"
  fi

  # change config
  jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json
  jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json
  jq ".inbounds[1].streamSettings.xhttpSettings.path=\"$XHTTP_PATH\"" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json

  SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json
  # jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json

  jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json
  jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" /config/config.json >/config/config.json_tmp && mv /config/config.json_tmp /config/config.json



  FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')
  # config info with green color
  echo -e "\033[32m" >/config/config_info.txt
  echo "IPV6: $IPV6" >>/config/config_info.txt
  echo "IPV4: $IPV4" >>/config/config_info.txt
  echo "UUID: $UUID" >>/config/config_info.txt
  echo "DEST: $DEST" >>/config/config_info.txt
  echo "PORT: $EXTERNAL_PORT" >>/config/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/config/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/config/config_info.txt
  echo "PUBLICKEY: $PUBLICKEY" >>/config/config_info.txt
  echo "NETWORK: $NETWORK" >>/config/config_info.txt
  echo "XHTTP_PATH: $XHTTP_PATH" >>/config/config_info.txt

  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV4}-wulabing_docker_xhttp_reality"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/config/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/config/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV6}-wulabing_docker_xhttp_reality"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/config/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/config/config_info.txt
  fi


  echo -e "\033[0m" >>/config/config_info.txt

fi

# show config info
cat /config/config_info.txt

# Setup logrotate cron job
echo "0 0 * * * /usr/sbin/logrotate /etc/logrotate.d/xray" | crontab -
# Start crond in background
crond

# run xray
exec /xray -config /config/config.json
