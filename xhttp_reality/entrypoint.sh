#!/bin/sh

# Start cron for log rotation
crond -b

CONFIG_PATH="/etc/xray/config.json"

if [ -f /config_info.txt ] && [ -f "$CONFIG_PATH" ]; then
  echo "config.json exist and initialized"
else
  # Check if config already has a valid UUID (idempotency check for mounted config)
  EXISTING_UUID=$(jq -r '.inbounds[1].settings.clients[0].id' "$CONFIG_PATH" 2>/dev/null)
  
  if [ "$EXISTING_UUID" != "xx" ] && [ -n "$EXISTING_UUID" ] && [ "$EXISTING_UUID" != "null" ]; then
      echo "Config already initialized with UUID: $EXISTING_UUID"
      UUID=$EXISTING_UUID
  else
      echo "Initializing config..."
      
      IPV6=$(curl -6 -sSL --connect-timeout 5 --retry 3 ip.sb || curl -6 -sSL --connect-timeout 5 --retry 3 ifconfig.co || echo "null")
      IPV4=$(curl -4 -sSL --connect-timeout 5 --retry 3 ip.sb || curl -4 -sSL --connect-timeout 5 --retry 3 ifconfig.co || echo "null")
      
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
        jq ".inbounds[0].port=$HOSTMODE_PORT" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
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
        PUBLICKEY=$(cat /key | grep "Password" | awk -F ': ' '{print $2}')
        echo "Private key: $PRIVATEKEY"
        echo "Public key: $PUBLICKEY"
      fi

      if [ -z "$NETWORK" ]; then
        echo "NETWORK is not set,set default value xhttp"
        NETWORK="xhttp"
      fi

      # change config
      jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq ".inbounds[1].streamSettings.xhttpSettings.path=\"$XHTTP_PATH\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"

      SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
      jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      # jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"

      jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
  fi

  # Always generate/update info file based on current config/env
  if [ -z "$PUBLICKEY" ]; then
      echo "Restoring info from existing config..."
      UUID=$(jq -r '.inbounds[1].settings.clients[0].id' "$CONFIG_PATH")
      DEST=$(jq -r '.inbounds[1].streamSettings.realitySettings.dest' "$CONFIG_PATH")
      SERVERNAMES=$(jq -r '.inbounds[1].streamSettings.realitySettings.serverNames | join(" ")' "$CONFIG_PATH")
      PRIVATEKEY=$(jq -r '.inbounds[1].streamSettings.realitySettings.privateKey' "$CONFIG_PATH")
      NETWORK=$(jq -r '.inbounds[1].streamSettings.network' "$CONFIG_PATH")
      XHTTP_PATH=$(jq -r '.inbounds[1].streamSettings.xhttpSettings.path' "$CONFIG_PATH")
      
      if [ -f /etc/xray/public.key ]; then
          PUBLICKEY=$(cat /etc/xray/public.key)
      else
          PUBLICKEY="UNKNOWN (Can't derive from private key)"
      fi
  fi

  FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')
  # config info with green color
  echo -e "\033[32m" >/config_info.txt
  echo "IPV6: $IPV6" >>/config_info.txt
  echo "IPV4: $IPV4" >>/config_info.txt
  echo "UUID: $UUID" >>/config_info.txt
  echo "DEST: $DEST" >>/config_info.txt
  echo "PORT: $EXTERNAL_PORT" >>/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/config_info.txt
  echo "PUBLICKEY/PASSWORD: $PUBLICKEY" >>/config_info.txt
  echo "NETWORK: $NETWORK" >>/config_info.txt
  echo "XHTTP_PATH: $XHTTP_PATH" >>/config_info.txt
  
  # Save public key for next time
  if [ "$PUBLICKEY" != "UNKNOWN (Can't derive from private key)" ]; then
      echo "$PUBLICKEY" > /etc/xray/public.key
  fi

  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV4}-damncrab_docker_xhttp_reality"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV6}-damncrab_docker_xhttp_reality"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi


  echo -e "\033[0m" >>/config_info.txt

fi

# show config info
cat /config_info.txt

# run xray
exec /xray -config "$CONFIG_PATH"
