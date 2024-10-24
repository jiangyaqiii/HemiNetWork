#===============================================================================================================================================================
systemctl stop hemi-restart.service
screen -S hemi -X quit
#===================================================================================================================================================================================
#=================================================升级0.5==================================================================================================================================

URL="https://github.com/hemilabs/heminetwork/releases/download/v0.5.0/heminetwork_v0.5.0_linux_amd64.tar.gz"
FILENAME="heminetwork_v0.5.0_linux_amd64.tar.gz"
DIRECTORY="/root/heminetwork_v0.5.0_linux_amd64"
ADDRESS_FILE="$HOME/popm-address.json"
BACKUP_FILE="$HOME/popm-address.json.bak"

echo "备份 address.json 文件..."
if [ -f "$ADDRESS_FILE" ]; then
    cp "$ADDRESS_FILE" "$BACKUP_FILE"
    echo "备份完成：$BACKUP_FILE"
else
    echo "未找到 address.json 文件，无法备份。"
fi

wget -q "$URL" -O "$FILENAME"
if [ $? -eq 0 ]; then
  echo "下载完成。"
else
  echo "下载失败。"
  exit 1
fi

echo "删除旧版本目录..."
rm -rf /root/heminetwork_v0.4.5_linux_amd64

echo "正在解压新版本..."
tar -xzf "$FILENAME" -C /root

if [ $? -eq 0 ]; then
    echo "解压完成。"
else
    echo "解压失败。"
    exit 1
fi

echo "删除压缩文件..."
rm -rf "$FILENAME"

# 恢复 address.json 文件
if [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$ADDRESS_FILE"
    echo "恢复 address.json 文件：$ADDRESS_FILE"
else
    echo "备份文件不存在，无法恢复。"
fi

echo "进入目录 $DIRECTORY..."
cd "$DIRECTORY" || { echo "目录 $DIRECTORY 不存在。"; exit 1; }

# 自动抓取 private_key
POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
# read -p "检查 https://mempool.space/zh/testnet 上的 sats/vB 值并输入 / Check the sats/vB value on https://mempool.space/zh/testnet and input: " POPM_STATIC_FEE

export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
export POPM_STATIC_FEE=100
export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public

screen -dmS hemi bash -c "./popmd"
