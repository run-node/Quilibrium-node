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
git clone https://github.com/a3165458/ceremonyclient.git

# 进入ceremonyclient/node目录
cd ~/ceremonyclient/node 
git switch release

# 赋予执行权限
chmod +x release_autorun.sh

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

# 创建一个screen会话并运行命令
screen -dmS Quili bash -c './release_autorun.sh'

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
cd ~/ceremonyclient/node && ./node-1.4.18-linux-amd64 -peer-id

}

function restart(){

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
    # 启动新的 screen 会话
    screen -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'
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

screen -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'
}

function repair(){

wget -O /root/ceremonyclient/node/.config/REPAIR "https://snapshots.cherryservers.com/quilibrium/REPAIR"


screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话
    screen -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'
    echo "新的 screen 会话已启动。"


echo "修复成功"
}

# 查询币余额
function check_balance() {
cd ceremonyclient/client
GOEXPERIMENT=arenas go build -o qclient main.go
sudo cp $HOME/ceremonyclient/client/qclient /usr/local/bin

qclient token balance

}

function Unlock_performance() {
cd ceremonyclient/node
git switch release-non-datacenter

# 赋予执行权限
chmod +x release_autorun.sh

# 创建一个 screen 会话并运行命令
screen -dmS Quili bash -c './release_autorun.sh'

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
    screen -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./release_autorun.sh'
    echo "新的 screen 会话已启动。"
}

function update(){
cd ceremonyclient
git remote -v
git remote set-url origin https://github.com/a3165458/ceremonyclient.git
git remote -v
echo "请重启节点"
}
function update_script() {
    SCRIPT_URL="https://raw.githubusercontent.com/a3165458/Quilibrium/main/Quili.sh"
    curl -o $SCRIPT_PATH $SCRIPT_URL
    chmod +x $SCRIPT_PATH
    echo "脚本已更新。请退出脚本后，执行bash Quili.sh 重新运行此脚本。"
}

function change(){

screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit
read -p "请输入需要使用的核心数量（例如1-26）: " cores

# 启动新的 screen 会话
screen -dmS Quili bash -c 'cd $HOME/ceremonyclient/node &&taskset -c $cores ./release_autorun.sh'
echo "已启动 screen 会话，使用核心：$cores"
screen -r Quili
}


command_exists() {
    command -v "$1" &> /dev/null
}


function grpcurl(){
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话
    screen -dmS Quili bash -c 'cd $HOME/ceremonyclient/node && ./release_autorun.sh'
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
    screen -r Quili
}

function check_grpcurl(){
grep "listenMultiaddr\|listenGrpcMultiaddr\|listenRESTMultiaddr" /root/ceremonyclient/node/.config/config.yml | awk -F ": " '{print $1,$2}'

}

# 主菜单
function main_menu() {
    clear
    echo "==========================自用脚本=============================="
    echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Telegram :https://t.me/linzeusasa"
    echo "安装后请备份您的钱包文件，路径为/root/ceremonyclient/node/.config中的config和keys两个文件"
    echo "查询余额官网：https://quilibrium.com/"
    echo "查询节点列表代码 screen -list(获取会话ID)"
    echo "查询会话Quili代码 screen -r ID"
    echo "关闭多余会话代码 screen -X -S ID quit"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志（查看完请按Ctrl+A后按D退出Screen）"
    echo "3. 查询钱包地址"
    echo "4. 重启节点（执行后请勿随意Ctrl+C中止程序）"
    echo "5. 备份钱包文件到root/quilibrium_key目录中"
    echo "6. 卸载节点(请提前备份好钱包文件)"
    echo "7. 修复卡块(失效)"
    echo "8. 查询余额(下版本更新余额)"
    echo "9. 修复余额查询(下版本更新余额)"
    echo "10. 更新版本git源"
    echo "11. 解锁物理机性能"
    echo "12. 更新脚本"
    echo "13. 设置核心数量"
    echo "14. 更新grpcurl"
    echo "15. 查询grcurl端口"
    read -p "请输入选项（1-15）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_address ;;
    4) restart ;;
    5) backup ;;
    6) uninstall ;;
    7) repair ;;
    8) check_balance ;;
    9) go_mod ;;
    10) update ;;
    11) Unlock_performance ;;
    12) update_script ;;
    13) change ;;
    14) grpcurl ;;
    15) check_grpcurl ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
