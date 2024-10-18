#===============================================================================================================================================================
systemctl stop hemi-restart.service
pkill screen
#===================================================================================================================================================================================
cd "$HOME/heminetwork"
cat ~/popm-address.json

# 自动抓取 private_key
POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
# read -p "检查 https://mempool.space/zh/testnet 上的 sats/vB 值并输入 / Check the sats/vB value on https://mempool.space/zh/testnet and input: " POPM_STATIC_FEE

export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
export POPM_STATIC_FEE=$POPM_STATIC_FEE
export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public

# ===================================公共模块===监控screen模块======================================================================
cd ~
echo '#!/bin/bash
while true
do
  if ! screen -list | grep -q "hemi"; then
    cd ~/heminetwork_v0.4.5_linux_amd64
    cat ~/popm-address.json
    POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
    export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
    export POPM_STATIC_FEE=$POPM_STATIC_FEE
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
    screen -dmS hemi bash -c "./popmd"
  fi
  sleep 10  # 每隔10秒检查一次
done' > regular_hemi.sh
##给予执行权限
chmod +x regular_hemi.sh
# ================================================================================================================================
echo ' [Unit]
Description=Restart hemi Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/regular_hemi.sh

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/hemi-restart.service
sudo systemctl daemon-reload
sudo systemctl enable hemi-restart.service
sudo systemctl start hemi-restart.service
