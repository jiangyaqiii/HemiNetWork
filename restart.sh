#===============================================================================================================================================================
systemctl stop hemi-restart.service
screen -S hemi -X quit
#===================================================================================================================================================================================
cd "$HOME/heminetwork"
cat ~/popm-address.json

# 自动抓取 private_key
POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
# read -p "检查 https://mempool.space/zh/testnet 上的 sats/vB 值并输入 / Check the sats/vB value on https://mempool.space/zh/testnet and input: " POPM_STATIC_FEE

export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
export POPM_STATIC_FEE=$POPM_STATIC_FEE
export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
cd ~/heminetwork
screen -dmS hemi bash -c "./popmd"
