#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Quili.sh"

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
gvm use go1.20.2

# 克隆仓库
git clone https://github.com/quilibriumnetwork/ceremonyclient

# 进入ceremonyclient/node目录
cd ceremonyclient/node 

# 赋予执行权限
chmod +x poor_mans_cd.sh

# 创建一个screen会话并运行命令
screen -dmS Quili bash -c './poor_mans_cd.sh'

}


# 查看常规版本节点日志
function check_service_status() {
    screen -r Quili
   
}



# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志(查看完请按Ctrl+A后D 退出S)"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;  
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
