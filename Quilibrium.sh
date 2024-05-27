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
sudo apt install git ufw bison screen binutils gcc make bsdmainutils -y

# 安装GVM
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source /root/.gvm/scripts/gvm

gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.17.13
gvm use go1.17.13
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.20.2

# 克隆仓库
git clone https://github.com/quilibriumnetwork/ceremonyclient

cd $HOME/ceremonyclient/client 
source /root/.gvm/scripts/gvm && gvm use go1.20.2
go mod tidy
GOEXPERIMENT=arenas go build -o /root/go/bin/qclient main.go

# 进入ceremonyclient/node目录
cd $HOME/ceremonyclient/node 
git switch release
# 赋予执行权限
chmod +x release_autorun.sh

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
    source /root/.gvm/scripts/gvm && gvm use go1.20.2
    cd $HOME/ceremonyclient/node/ && GOEXPERIMENT=arenas go run ./... -balance
}

# 查询币余额
function go_mod() {
    cd $HOME/ceremonyclient/client 
    source /root/.gvm/scripts/gvm && gvm use go1.20.2
    go mod tidy
    GOEXPERIMENT=arenas go build -o /root/go/bin/qclient main.go
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
    echo "7. 下载快照(目前不需要同步快照)"
    echo "8. 修复卡块"
    echo "9. 查询余额(暂未修复)"
    echo "10. 更新go模块(查询余额go模块报错请执行该步骤)"
    echo "11. 更新pow版本(旧版本请执行该步骤)"
    read -p "请输入选项（1-11）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;; 
    3) check_address ;;
    4) restart ;;
    5) backup ;;
    6) uninstall ;;
    7) download ;;
    8) repair ;;
    9) check_balance ;;
    10) go_mod ;;
    11) pow ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
