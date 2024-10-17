echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
echo "ulimit -v 640000;" >> ~/.bashrc
source ~/.bashrc

apt-get install -y jq

# 功能：自动安装缺少的依赖项 (git 和 make)
install_dependencies() {
    for cmd in git make; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd 未安装。正在自动安装 $cmd... / $cmd is not installed. Installing $cmd..."

            # 检测操作系统类型并执行相应的安装命令
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update
                sudo apt install -y $cmd
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install $cmd
            else
                echo "不支持的操作系统。请手动安装 $cmd。/ Unsupported OS. Please manually install $cmd."
                exit 1
            fi
        fi
    done
    echo "已安装所有依赖项。/ All dependencies have been installed."
}
check_go_version() {
    if command -v go >/dev/null 2>&1; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        MINIMUM_GO_VERSION="1.22.2"

        if [ "$(printf '%s\n' "$MINIMUM_GO_VERSION" "$CURRENT_GO_VERSION" | sort -V | head -n1)" = "$MINIMUM_GO_VERSION" ]; then
            echo "当前 Go 版本满足要求: $CURRENT_GO_VERSION / Current Go version meets the requirement: $CURRENT_GO_VERSION"
        else
            echo "当前 Go 版本 ($CURRENT_GO_VERSION) 低于要求的版本 ($MINIMUM_GO_VERSION)，将安装最新的 Go。/ Current Go version ($CURRENT_GO_VERSION) is below the required version ($MINIMUM_GO_VERSION). Installing the latest Go."
            install_go
        fi
    else
        echo "未检测到 Go，正在安装 Go。/ Go is not detected. Installing Go."
        install_go
    fi
}
install_go() {
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    echo "Go 安装完成，版本: $(go version) / Go installation completed, version: $(go version)"
}
# 功能：检查并安装 Node.js 和 npm
install_node() {
    echo "检测到未安装 npm。正在安装 Node.js 和 npm... / npm is not installed. Installing Node.js and npm..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install node
    else
        echo "不支持的操作系统。请手动安装 Node.js 和 npm。/ Unsupported OS. Please manually install Node.js and npm."
        exit 1
    fi

    echo "Node.js 和 npm 安装完成。/ Node.js and npm installation completed."
}
# 功能：安装 pm2
install_pm2() {
    if ! command -v npm &> /dev/null; then
        echo "npm 未安装。/ npm is not installed."
        install_node
    fi

    if ! command -v pm2 &> /dev/null; then
        echo "pm2 未安装。正在安装 pm2... / pm2 is not installed. Installing pm2..."
        npm install -g pm2
    else
        echo "pm2 已安装。/ pm2 is already installed."
    fi
}
download_and_setup() {
    wget https://github.com/hemilabs/heminetwork/releases/download/v0.4.5/heminetwork_v0.4.5_linux_amd64.tar.gz -O heminetwork_v0.4.5_linux_amd64.tar.gz

    # 创建目标文件夹 (如果不存在)
    TARGET_DIR="$HOME/heminetwork"
    mkdir -p "$TARGET_DIR"

    # 解压文件到目标文件夹
    tar -xvf heminetwork_v0.4.5_linux_amd64.tar.gz -C "$TARGET_DIR"

    # 移动文件到 heminetwork 目录
    mv "$TARGET_DIR/heminetwork_v0.4.5_linux_amd64/"* "$TARGET_DIR/"
    rmdir "$TARGET_DIR/heminetwork_v0.4.5_linux_amd64"

    # 切换到目标文件夹
    cd $HOME/heminetwork
    ./popmd --help
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
}
setup_environment() {
    cd "$HOME/heminetwork"
    cat ~/popm-address.json

    # 自动抓取 private_key
    POPM_BTC_PRIVKEY=$(jq -r '.private_key' ~/popm-address.json)
    # read -p "检查 https://mempool.space/zh/testnet 上的 sats/vB 值并输入 / Check the sats/vB value on https://mempool.space/zh/testnet and input: " POPM_STATIC_FEE
    
    export POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY
    export POPM_STATIC_FEE=$POPM_STATIC_FEE
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
}
# 功能3：使用 pm2 启动 popmd
start_popmd() {
    # cd "$HOME/heminetwork"
    # screen -dmS hemi bash -c "./popmd"
    # # pm2 start ./popmd --name popmd
    # # pm2 save
    # echo "popmd 已通过 screen 启动。"
    # ===================================公共模块===监控screen模块======================================================================
    cd ~
    echo '#!/bin/bash
    while true
    do
      if ! screen -list | grep -q "hemi"; then
        cd ~/heminetwork
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
}


install_dependencies;
check_go_version;
install_pm2;
download_and_setup;
setup_environment;
start_popmd;

cd ~
rm -f start.sh
