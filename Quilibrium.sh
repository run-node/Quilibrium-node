#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Quilibrium.sh"

# 节点安装功能
function install_node() {

# 增加swap空间
sudo mkdir /swap
sudo fallocate -l 24G /swap/swapfile
sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile
sudo swapon /swap/swapfile
echo '/swap/swapfile swap swap defaults 0 0' >> /etc/fstab

# 向/etc/sysctl.conf文件追加内容
echo -e "\n# 自定义最大接收和发送缓冲区大小" >> /etc/sysctl.conf
echo "net.core.rmem_max=600000000" >> /etc/sysctl.conf
echo "net.core.wmem_max=600000000" >> /etc/sysctl.conf

echo "配置已添加到/etc/sysctl.conf"

# 重新加载sysctl配置以应用更改
sysctl -p

echo "sysctl配置已重新加载"

# 更新并升级Ubuntu软件包
sudo apt update && sudo apt -y upgrade 

# 安装wget、screen和git等组件
sudo apt install git ufw bison screen binutils gcc make bsdmainutils cpulimit gawk -y

wget -P /tmp https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_amd64.deb
sudo apt-get install -y /tmp/grpcurl_1.9.1_linux_amd64.deb
rm /tmp/grpcurl_1.9.1_linux_amd64.deb

# 下载并安装gvm
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source /root/.gvm/scripts/gvm

# 获取系统架构
ARCH=$(uname -m)

# 安装并使用go1.4作为bootstrap
gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT

# 根据系统架构安装相应的Go版本
if [ "$ARCH" = "x86_64" ]; then
  gvm install go1.17.13
  gvm use go1.17.13
  export GOROOT_BOOTSTRAP=$GOROOT

  gvm install go1.20.2
  gvm use go1.20.2
elif [ "$ARCH" = "aarch64" ]; then
  gvm install go1.17.13 -B
  gvm use go1.17.13
  export GOROOT_BOOTSTRAP=$GOROOT

  gvm install go1.20.2 -B
  gvm use go1.20.2
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

# 克隆仓库
git clone -b release-cdn https://git.dadunode.com/smeb_y/ceremonyclient.git

# 进入ceremonyclient/node目录
cd ~/ceremonyclient/node 
git switch release

curl -o /root/ceremonyclient/node/release_autorun.sh https://raw.githubusercontent.com/a3165458/Quilibrium/refs/heads/main/release_autorun.sh


# 赋予执行权限
chmod +x release_autorun.sh

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

# 创建一个screen会话并运行命令
> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'


}


# 查看节点日志
function check_service_status() {
    count=$(screen -ls | grep Quili | wc -l)

    if [ $count -gt 1 ]; then
        echo "存在多个Quili会话----请进入screen查询后手动关闭多余的screen(screen -list查询  screen -X -S ID quit关闭会话)"
    fi
    screen -r Quili

}

function check_address(){
cd ~/ceremonyclient/node/ && ./node-2.0.2.3-linux-amd64 --node-info

}

function restart(){

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    # 启动新的 screen 会话
    cd ~/ceremonyclient/node
    git pull
    > /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

    echo "新的 screen 会话已启动。"
    screen -r Quili
}


function backup(){
cp $HOME/ceremonyclient/node/.config/{config.yml,keys.yml} $HOME
mkdir -p $HOME/quilibrium_key && cp /root/ceremonyclient/node/.config/{config.yml,keys.yml} $HOME/quilibrium_key

}

function uninstall(){


screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

rm -rf ceremonyclient
}

function download(){
screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

wget -O https://snapshots.cherryservers.com/quilibrium/store.zip
apt install unzip
unzip store.zip
cd ~/ceremonyclient/node/.config
rm -rf store
cd ~
mv store ~/ceremonyclient/node/.config

> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

}

function repair(){

wget -O /root/ceremonyclient/node/.config/REPAIR "https://snapshots.cherryservers.com/quilibrium/REPAIR"


screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话
    > /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

    echo "新的 screen 会话已启动。"


echo "修复成功"
screen -r Quili

}

# 查询币余额
function check_uxtobalance() {
cd /root/ceremonyclient/client
./qclient-2.0.2.4-linux-amd64 token coins --config /root/ceremonyclient/node/.config

}

function check_balance() {
cd /root/ceremonyclient/client
./qclient-2.0.2.4-linux-amd64 token balance --config /root/ceremonyclient/node/.config

}

function Unlock_performance() {
cd ceremonyclient/node
git switch release-non-datacenter

# 赋予执行权限
chmod +x release_autorun.sh

# 创建一个 screen 会话并运行命令
> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

screen -r Quili
}

# 查询币余额
function go_mod() {
    source /root/.gvm/scripts/gvm && gvm use go1.20.2
    cd ceremonyclient/client
    GOEXPERIMENT=arenas go build -o qclient main.go
    sudo cp $HOME/ceremonyclient/client/qclient /usr/local/bin
}

function pow() {
    cd $HOME/ceremonyclient/node
    git pull
    git checkout release
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    # 启动新的 screen 会话
    > /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

    echo "新的 screen 会话已启动。"
}

function update(){
screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
cd $HOME/ceremonyclient/node
git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git
git pull
git checkout release-cdn
> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

echo "已启动 screen 会话，清前往查看日志"
}

function update_script() {
    SCRIPT_URL="https://raw.githubusercontent.com/a3165458/Quilibrium/main/Quili.sh"
    curl -o $SCRIPT_PATH $SCRIPT_URL
    chmod +x $SCRIPT_PATH
    echo "脚本已更新。请退出脚本后，执行bash Quili.sh 重新运行此脚本。"
    screen -r Quili

}

function change(){

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
read -p "请输入需要使用的核心数量（例如1-26）: " cores

# 启动新的 screen 会话
> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'

echo "已启动 screen 会话，使用核心：$cores"
screen -r Quili
}


command_exists() {
    command -v "$1" &> /dev/null
}


function grpcurl(){
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    sed -i 's#/ip4/0.0.0.0/udp/8336/quic#/ip4/0.0.0.0/tcp/8336#g' /root/ceremonyclient/node/.config/config.yml
    sed -i 's|listenGrpcMultiaddr: ""|listenGrpcMultiaddr: "/ip4/127.0.0.1/tcp/8337"|' /root/ceremonyclient/node/.config/config.yml
    sed -i 's|listenRESTMultiaddr: ""|listenRESTMultiaddr: "/ip4/127.0.0.1/tcp/8338"|' /root/ceremonyclient/node/.config/config.yml

        # Install cpulimit if not installed
    if ! command_exists cpulimit; then
        sudo apt install -y cpulimit
    else
        echo "cpulimit is already installed"
    fi

    # Install gawk if not installed
    if ! command_exists gawk; then
        sudo apt install -y gawk
    else
        echo "gawk is already installed"
    fi

    # Install grpcurl if not installed
    if ! command_exists grpcurl; then
        wget -P /tmp https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_amd64.deb
        sudo apt-get install -y /tmp/grpcurl_1.9.1_linux_amd64.deb
        rm /tmp/grpcurl_1.9.1_linux_amd64.deb
    else
        echo "grpcurl is already installed"
    fi
}

function qclient(){
    # 切换到目标目录
    cd /root/ceremonyclient/client || exit
    
    # 获取并下载最新的 linux-amd64 文件
    for f in $(curl -s https://releases.quilibrium.com/qclient-release | grep linux-amd64); do
        echo "Processing $f..."
        
        # 如果文件存在，删除它
        if [ -f "$f" ]; then
            echo "Removing existing file: $f"
            rm "$f"
        fi
        
        # 下载文件
        echo "Downloading $f..."
        curl -s -O "https://releases.quilibrium.com/$f"
    done
    chmod +x qclient-2*
    echo "Update complete!"

}

function qclient2(){
    #!/bin/bash

    # 切换到目标目录
    cd /root/ceremonyclient/node || exit
    
    # 获取并下载最新的 linux-amd64 文件
    for f in $(curl -s https://releases.quilibrium.com/qclient-release | grep linux-amd64); do
        echo "Processing $f..."
        
        # 如果文件存在，删除它
        if [ -f "$f" ]; then
            echo "Removing existing file: $f"
            rm "$f"
        fi
        
        # 下载文件
        echo "Downloading $f..."
        curl -s -O "https://releases.quilibrium.com/$f"
    done
    chmod +x qclient-2*
    echo "Update complete!"

}

function up(){
screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
cd $HOME/ceremonyclient/node
git checkout main
git pull
git branch -D release
git remote set-url origin https://github.com/quilibriumnetwork/ceremonyclient.git
git pull
git checkout release
git reset --hard origin/release
git fetch --all
git clean -df
echo "请重启节点······"
}
# 主菜单

function increment(){
    grep "increment" /root/screen_log.txt | while read -r line; do
        ts=$(echo "$line" | grep -oP '"ts":\K[0-9.]+')
        increment=$(echo "$line" | grep -oP '"increment":\K[0-9]+')
        formatted_time=$(date -u -d @"${ts}" +"%Y-%m-%d %H:%M:%S" --utc)
        formatted_time=$(date -d "${formatted_time} +8 hours" +"%Y-%m-%d %H:%M:%S")
        echo "当前时间: ${formatted_time} ---- increment: ${increment}"
    done

}
function main_menu() {
    clear
    echo "==========================自用脚本=============================="
    echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Telegram :https://t.me/linzeusasa"
    echo "安装后请备份您的钱包文件，路径为/root/ceremonyclient/node/.config中的config和keys两个文件"
    echo "查询余额官网：https://quilibrium.com/reward"
    echo "查询节点列表代码 screen -list(获取会话ID)"
    echo "查询会话Quili代码 screen -r ID"
    echo "关闭多余会话代码 screen -X -S ID quit"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志（查看完请按Ctrl+A后按D退出Screen）"
    echo "3. 查询钱包地址"
    echo "4. 重启节点"
    echo "5. 备份钱包文件到root/quilibrium_key目录中"
    echo "6. 卸载节点(请提前备份好钱包文件)"
    echo "7. 查询uxto余额"
    echo "8. 查询总余额"
    echo "9. 安装grpcurl"
    echo "10. 安装qclient"
    echo "11. 安装qclient到node文件夹"
    echo "12. 查询increment值"
    read -p "请输入选项（1-9）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_address ;;
    4) restart ;;
    5) backup ;;
    6) uninstall ;;
    7) check_uxtobalance ;;
    8) check_balance ;;
    9) grpcurl ;;
    10) qclient ;;
    11) qclient2 ;;
    12) increment ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
