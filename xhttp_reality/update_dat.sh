#!/bin/sh

# Update geosite.dat
echo "Updating geosite.dat..."
wget -q -O /geosite.dat.new https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat
if [ $? -eq 0 ]; then
    mv /geosite.dat.new /geosite.dat
    echo "geosite.dat updated."
else
    echo "Failed to update geosite.dat"
    rm -f /geosite.dat.new
fi

# Update geoip.dat
echo "Updating geoip.dat..."
wget -q -O /geoip.dat.new https://github.com/v2fly/geoip/releases/latest/download/geoip.dat
if [ $? -eq 0 ]; then
    mv /geoip.dat.new /geoip.dat
    echo "geoip.dat updated."
else
    echo "Failed to update geoip.dat"
    rm -f /geoip.dat.new
fi

# Reload Xray (optional, depending on if Xray hot-reloads these files. Usually restart is needed or send SIGHUP)
# Xray core typically needs a restart to reload dat files completely unless used in a specific way, 
# but simply killing it might stop the container if not managed by supervisor. 
# For simple docker setup, we just update files. User can restart container if they need immediate effect.
echo "Update finished."
