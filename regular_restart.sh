# ===================================公共模块===监控screen模块======================================================================
cd ~
echo '#!/bin/bash
while true
do
  if ! screen -list | grep -q "hemi"; then
    cd ~/heminetwork_v0.4.4_linux_amd64
    cat ~/popm-address.json
    POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
    export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
    export POPM_STATIC_FEE=300
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
    screen -dmS hemi bash -c "./popmd"
  fi
  sleep 10  # 每隔10秒检查一次
done' > regular.sh
##给予执行权限
chmod +x regular.sh
# ================================================================================================================================
echo ' [Unit]
Description=Restart hemi Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/regular.sh

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/hemi-restart.service
sudo systemctl daemon-reload
sudo systemctl enable hemi-restart.service
sudo systemctl start hemi-restart.service
echo '==flag:v2===='
rm -f regular.restart.sh
# ================================================flag:v2=====================================================================================
# echo '[Unit]
# Description=Timer for restarting Ocean Docker containers every 24 hours

# [Timer]
# OnCalendar=*:0/1
# Persistent=true

# [Install]
# WantedBy=timers.target' > /etc/systemd/system/ocean-restart.timer
# sudo systemctl start ocean-restart.timer
# sudo systemctl enable ocean-restart.timer
