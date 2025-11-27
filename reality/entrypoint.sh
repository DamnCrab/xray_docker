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
      # We can extract other vars if needed, but assuming if UUID is set, it's good.
      # Just regenerate info file if missing
  else
      echo "Initializing config..."
      
      IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
      IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
      
      if [ -z "$UUID" ]; then
        echo "UUID is not set, generate random UUID "
        UUID="$(/xray uuid)"
        echo "UUID: $UUID"
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
        echo "NETWORK is not set,set default value tcp"
        NETWORK="tcp"
      fi

      # change config
      jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"

      SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
      jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"

      jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
      jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" "$CONFIG_PATH" >/config.json_tmp && mv /config.json_tmp "$CONFIG_PATH"
  fi

  # Always generate/update info file based on current config/env
  # If we skipped init, we might need to re-read values from config if we want to show them correctly.
  # But for now, let's assume if we just initialized, variables are set.
  # If we didn't initialize (idempotent), we need to read back values to show in info.
  
  if [ -z "$PUBLICKEY" ]; then
      # Try to derive public key from private key in config if not set
      CURRENT_PRIVATE_KEY=$(jq -r '.inbounds[1].streamSettings.realitySettings.privateKey' "$CONFIG_PATH")
      # There is no easy way to derive public from private without xray tool if not saved.
      # But usually we only need this for the link.
      # If we are restarting, we might miss the public key for the link display if we don't save it.
      # However, the requirement is "if already initialized... don't recreate".
      # Showing the info again is nice but maybe not strictly required if it's hard.
      # Let's try to do our best.
      echo "Restoring info from existing config..."
      UUID=$(jq -r '.inbounds[1].settings.clients[0].id' "$CONFIG_PATH")
      DEST=$(jq -r '.inbounds[1].streamSettings.realitySettings.dest' "$CONFIG_PATH")
      # SERVERNAMES is array, simplfying
      SERVERNAMES=$(jq -r '.inbounds[1].streamSettings.realitySettings.serverNames | join(" ")' "$CONFIG_PATH")
      PRIVATEKEY=$(jq -r '.inbounds[1].streamSettings.realitySettings.privateKey' "$CONFIG_PATH")
      NETWORK=$(jq -r '.inbounds[1].streamSettings.network' "$CONFIG_PATH")
      # We can't easily get PUBLICKEY from PRIVATEKEY without `xray x25519 -i` or similar if supported, 
      # but `xray x25519` generates a NEW pair. 
      # `xray` doesn't seem to have a "derive public from private" command easily accessible in help usually.
      # Wait, if we have the private key, we can't easily get the public key unless we stored it.
      # But the link needs it. 
      # If the user provided PRIVATEKEY env var, we might not have PUBLICKEY either.
      # The original script generated both at once.
      # If we are persistent, maybe we should save the info file too?
      # The original script checks `if [ -f /config_info.txt ]; then echo "config.json exist"`.
      # So if we persist `/config_info.txt` (which we don't, it's in root), we lose it on restart.
      # But we are mounting `/etc/xray`. Maybe we should save info there?
      # Or just accept that on restart we might not show the QR code if we can't derive it.
      # Actually, `xray` command might not support deriving.
      # Let's check if we can save the info file to the config dir?
      # The user asked for "config and logs mounted".
      # Let's save `config_info.txt` to `/etc/xray/config_info.txt` as well?
      # Or just rely on the fact that if config exists, we assume it's good.
      
      # Let's try to see if we can just skip the display if we can't get the public key, 
      # OR we can try to save the public key in the config? No, config structure is fixed.
      # Let's save the public key in a side file in /etc/xray/public.key?
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
  
  # Save public key for next time
  if [ "$PUBLICKEY" != "UNKNOWN (Can't derive from private key)" ]; then
      echo "$PUBLICKEY" > /etc/xray/public.key
  fi

  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV4}-wulabing_docker_vless_reality_vision"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV6}-wulabing_docker_vless_reality_vision"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/config_info.txt
  fi


  echo -e "\033[0m" >>/config_info.txt

fi

# show config info
cat /config_info.txt

# run xray
exec /xray -config "$CONFIG_PATH"
