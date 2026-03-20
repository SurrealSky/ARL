#!/bin/bash
# ARL 自动安装配置脚本
# 版本: 2.0
#-----------------------------
# 格式化配置
#-----------------------------
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'
BOLD='\033[1m'

#-----------------------------
# 全局变量
#-----------------------------
ARL_VERSION="2.0"
BASE_DIR="/opt"
ARL_DIR="$BASE_DIR/ARL"
ARL_NPoC_DIR="$BASE_DIR/ARL-NPoC"
GEO_DATA_DIR="/data/GeoLite2"

# 国内常用下载链接 (GitCode)
GITCODE_BASE_URL="https://raw.gitcode.com/msmoshang/arl_files/blobs"
GITCODE_BASE_URL_ARL="https://raw.gitcode.com/msmoshang/ARL/blobs"
GITCODE_BASE_URL_ADDF="https://raw.gitcode.com/msmoshang/ADD-ARL-Finger/blobs"
NUCLEI_URL_CN="$GITCODE_BASE_URL/23658ed3383635877d517345be25df36bfdf774f/nuclei_3.3.9_linux_amd64.zip"
WIH_URL_CN="$GITCODE_BASE_URL/ca1f54e9ea46855fea153cb76fb854e870d3bd8a/wih_linux_amd64"
NCRACK_URL_CN="$GITCODE_BASE_URL/9a6b0fbf8b9e377e1ed234347a3097c5c28ebd8d/ncrack"
NCRACK_SERVICES_URL_CN="$GITCODE_BASE_URL/cfd6e29efb2ab97e84f346206fe5d9719f242a8f/ncrack-services"
GEO_ASN_URL_CN="$GITCODE_BASE_URL/0737adc55cb78b6b06973d55d6012d66bcc1d219/GeoLite2-ASN.mmdb"
GEO_CITY_URL_CN="$GITCODE_BASE_URL/cb513cf65f6b6611bd3aa6b6ca61ccbed2858ec2/GeoLite2-City.mmdb"
ADD_FINGER_SCRIPT_URL="$GITCODE_BASE_URL_ADDF/29d142c75881c6c75d7a20bae4f5c33a5b08bf81/ADD-ARL-finger.py"
DEFAULT_FINGER_URL="$GITCODE_BASE_URL_ARL/882cce400c6038c71f168e7d2bc180fedb5ca8f0/finger.json"
GET_PIP_SCRIPT_CN="$GITCODE_BASE_URL/fd48c7fdef802d8bb86ace74134c553f0317258c/get-pip.py"

# 国外常用下载链接 (GitHub/Git.io)
GITHUB_BASE_URL="https://raw.githubusercontent.com/msmoshang/arl_files/master"
NUCLEI_URL="https://github.com/projectdiscovery/nuclei/releases/download/v3.3.9/nuclei_3.3.9_linux_amd64.zip"
WIH_URL="$GITHUB_BASE_URL/wih/wih_linux_amd64"
NCRACK_URL="$GITHUB_BASE_URL/ncrack"
NCRACK_SERVICES_URL="$GITHUB_BASE_URL/ncrack-services"
GEO_ASN_URL="https://git.io/GeoLite2-ASN.mmdb" 
GEO_CITY_URL="https://git.io/GeoLite2-City.mmdb"
GET_PIP_SCRIPT="https://bootstrap.pypa.io/pip/3.6/get-pip.py"

#-----------------------------
# 基础功能函数
#-----------------------------

# 输出带颜色的消息
color_echo() {
    local color="$1"
    shift
    echo -e "${color}${BOLD}$@${RESET}"
}
# 打印分割线
print_separator() {
    local char="${1:-=}"
    local length="${2:-60}"
    printf '%*s\n' "$length" | tr ' ' "$char"
}
# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        color_echo $RED "错误：命令 '$1' 未找到，请先安装。"
        exit 1
    fi
}
# 检查并安装软件包 (自动识别发行版)
install_package() {
    local package_name="$1"
    if ! command -v "$package_name" &> /dev/null; then
        color_echo $YELLOW "正在安装 $package_name ..."
        if [[ -f /etc/debian_version ]]; then
             # Debian/Ubuntu 系
            sudo apt-get update && sudo apt-get install -y "$package_name"
        elif [[ -f /etc/redhat-release ]]; then
            # CentOS/RHEL 系
            sudo yum install -y "$package_name"
        elif [[ -f /etc/fedora-release ]]; then
            # Fedora 系
            sudo dnf install -y "$package_name"
        elif [[ -f /etc/arch-release ]]; then
            # Arch Linux 系
            sudo pacman -S --noconfirm "$package_name"
        else
            color_echo $RED "不支持的 Linux 发行版，请手动安装 $package_name。"
            exit 1
        fi
        color_echo $GREEN "$package_name 安装完成。"
    else
        color_echo $GREEN "$package_name 已安装。"
    fi
}
# 检查并安装 git
check_and_install_git() {
    install_package git
}
#安装管理工具
manage_arl() {
  local script_source="/opt/ARL/misc/manage.sh" 
  local command_path="/usr/local/bin/arl"     

  if [ ! -f "$command_path" ]; then
    color_echo "$YELLOW" "安装ARL管理面板..."

    # 使用 cp 和 chmod，并捕获错误
    if cp "$script_source" "$command_path" && chmod +x "$command_path"; then
      color_echo "$YELLOW" "ARL 管理面板已安装成功"
      color_echo "$YELLOW" "使用arl命令就可唤起面板"
    else
      # 安装失败
      color_echo "$RED" "错误：安装ARL管理面板失败。"
      color_echo "$RED" "请检查以下可能原因："
      color_echo "$RED" "  1. 确保 /opt/ARL/misc/manage.sh 文件存在且可读。"
      color_echo "$RED" "  2. 确保您有足够的权限写入 $command_path。"
      color_echo "$RED" "  3. 检查磁盘空间是否充足。"
      exit 1  # 以非零退出码退出，表示错误
    fi
  else
    color_echo "$YELLOW" "ARL 管理面板已存在于 $command_path, 无需安装."
  fi
}
# 下载文件 (自动选择 wget 或 curl)
download_file() {
    local url="$1"
    local output_file="$2"
    local quiet="${3:-true}"  # 默认静默下载
    local q_flag=""

    if [ "$quiet" = true ]; then
        q_flag="-q"
    fi

    if command -v curl &> /dev/null; then
        curl -sSL "$url" -o "$output_file"
    elif command -v wget &> /dev/null; then
        wget $q_flag --continue "$url" -O "$output_file"
    else
        color_echo $RED "错误：curl 和 wget 都不存在，无法下载文件。"
        exit 1
    fi

    if [ $? -ne 0 ]; then
        color_echo $RED "文件下载失败: $url"
        exit 1
    fi
}

# 安装 nmap (支持 .rpm 和 alien 转换)
install_nmap() {
    if ! command -v nmap &> /dev/null; then
        color_echo $YELLOW "安装 nmap..."
        local nmap_rpm="nmap-7.95-3.x86_64.rpm"
        local nmap_deb="nmap_7.95-4_amd64.deb"
        local nmap_url="https://nmap.org/dist/$nmap_rpm"

        if [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu 系, 需要先安装 alien
            install_package alien
            download_file "$nmap_url" "$nmap_rpm"
            sudo alien "./$nmap_rpm"
            sudo dpkg -i "$nmap_deb"
            rm -f "$nmap_rpm" "$nmap_deb"
        elif [[ -f /etc/redhat-release || -f /etc/fedora-release ]]; then
            # CentOS/RHEL/Fedora 系
            download_file "$nmap_url" "$nmap_rpm"
            sudo rpm -Uvh "$nmap_rpm"
            rm -f "$nmap_rpm"
        else
             color_echo $RED "不支持的 Linux 发行版，请手动安装nmap。"
             exit 1
        fi
    fi
}

# 安装 nuclei (区分国内外)
install_nuclei() {
    if ! command -v nuclei &> /dev/null; then
        color_echo $YELLOW "安装 nuclei..."
        local nuclei_zip="nuclei_3.3.9_linux_amd64.zip"
        local nuclei_url

        if is_cn_env; then
            nuclei_url="$NUCLEI_URL_CN"
        else
            nuclei_url="$NUCLEI_URL"
        fi

        download_file "$nuclei_url" "$nuclei_zip"
        unzip "$nuclei_zip" && sudo mv nuclei /usr/bin/ && rm -f "$nuclei_zip"
        nuclei -ut
    fi
}

# 安装 wih (区分国内外)
install_wih() {
    if ! command -v wih &> /dev/null; then
        color_echo $YELLOW "安装 wih..."
        local wih_url
        if is_cn_env; then
            wih_url="$WIH_URL_CN"
        else
            wih_url="$WIH_URL"
        fi
        download_file "$wih_url" "/usr/bin/wih"
        sudo chmod +x /usr/bin/wih
        wih --version
    fi
}

# 安装 ncrack (区分国内外)
install_ncrack() {
    if [ ! -f /usr/local/bin/ncrack ]; then
        color_echo $YELLOW "安装 ncrack..."
        local ncrack_url
        if is_cn_env; then
            ncrack_url="$NCRACK_URL_CN"
        else
            ncrack_url="$NCRACK_URL"
        fi
        download_file "$ncrack_url" "/usr/local/bin/ncrack"
        sudo chmod +x /usr/local/bin/ncrack
    fi

    mkdir -p /usr/local/share/ncrack
    if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
        color_echo $YELLOW "下载 ncrack-services..."
         local ncrack_services_url
        if is_cn_env; then
            ncrack_services_url="$NCRACK_SERVICES_URL_CN"
        else
            ncrack_services_url="$NCRACK_SERVICES_URL"
        fi
        download_file "$ncrack_services_url" "/usr/local/share/ncrack/ncrack-services"
    fi
}

# 下载 GeoLite2 数据库 (区分国内外)
download_geolite2() {
    mkdir -p "$GEO_DATA_DIR"
    for db in GeoLite2-ASN.mmdb GeoLite2-City.mmdb; do
        if [ ! -f "$GEO_DATA_DIR/$db" ]; then
            color_echo $YELLOW "下载 $db..."
            local geo_url
            if is_cn_env; then
                case "$db" in
                    GeoLite2-ASN.mmdb) geo_url="$GEO_ASN_URL_CN" ;;
                    GeoLite2-City.mmdb) geo_url="$GEO_CITY_URL_CN" ;;
                esac
            else
               case "$db" in
                    GeoLite2-ASN.mmdb) geo_url="$GEO_ASN_URL" ;;
                    GeoLite2-City.mmdb) geo_url="$GEO_CITY_URL" ;;
                esac
            fi
            download_file "$geo_url" "$GEO_DATA_DIR/$db"
        fi
    done
}

# 安装 pip3.6 (区分国内外)
install_pip36() {
  if [ ! -f /usr/local/bin/pip3.6 ]; then
    color_echo $YELLOW "安装 pip3.6..."
    local get_pip_url
    local pip_mirror=""

    if is_cn_env; then
      get_pip_url="$GET_PIP_SCRIPT_CN"
      pip_mirror="-i https://mirrors.aliyun.com/pypi/simple/"
    else
      get_pip_url="$GET_PIP_SCRIPT"
    fi

    download_file "$get_pip_url" "get-pip.py"
    python3.6 get-pip.py $pip_mirror
    pip3.6 --version

    if is_cn_env; then
      pip3.6 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
    fi
    rm -f get-pip.py
  fi
}

# 判断是否为国内网络环境 (根据能否访问 google.com)
is_cn_env() {
    return 1
}

# 获取 MongoDB 安装源配置 (根据发行版和版本)
get_mongodb_repo_config() {
    local os_id="$1"
    local os_version_id="$2"
    local repo_config=""

    case "$os_id$os_version_id" in
        centos7|centos8|rhel8|rocky8.10)
            repo_config=$(cat <<EOF
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF
)
            ;;
        ubuntu20.04)
            repo_config="deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse"
            ;;
        *)
            color_echo $RED "不支持的操作系统: $os_id$os_version_id"
            exit 1
            ;;
    esac
    echo "$repo_config"
}

# 获取 RabbitMQ 安装源配置 (根据发行版和版本)
get_rabbitmq_repo_config() {
    local os_id="$1"
    local os_version_id="$2"
    local repo_config=""

    case "$os_id$os_version_id" in
        centos8|rhel8|rocky8.10)
            repo_config=$(cat <<EOF
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server-source]
name=rabbitmq_rabbitmq-server-source
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF
)
            ;;
        ubuntu20.04)
            repo_config=""  # Ubuntu 通过 apt 直接安装，不需要额外配置源
            ;;
        centos7)
            repo_config=""
            ;;
        *)
            color_echo $RED "不支持的操作系统或版本: $os_id$os_version_id"
            exit 1
            ;;
    esac
    echo "$repo_config"
}

#----------------------------------
# 其余函数 (根据需要修改 URL 和路径)
#----------------------------------

# 获取公网 IP 并显示 ARL 访问地址
ipinfo() {
    local ip=$(curl -s https://ipinfo.io/ip)
    if [[ -z "$ip" ]]; then
        color_echo $YELLOW "警告：无法获取公网 IP，可能影响 ARL 访问。"
    else
        color_echo $GREEN "ARL 访问地址: https://${ip}:5003"
    fi
}

# 全局变量，存储随机生成的密码
ARLRANDOM_PASS=""

# 生成随机密码并初始化 MongoDB 用户
rand_pass() {
    # 生成16位随机密码
    ARLRANDOM_PASS=$(tr -cd '[:alnum:]' < /dev/urandom | head -c 16)
    local SALT="arlsalt!@#" # 定义盐值

  # 创建 mongo-init.js 文件 (覆盖旧文件)
    cat <<EOF > /opt/ARL/docker/mongo-init.js
db.user.drop();
db.user.insert({ username: 'admin',  password: hex_md5('${SALT}'+'${ARLRANDOM_PASS}') });
EOF
    color_echo $GREEN "MongoDB 初始化脚本已生成。"
}

# 输出用户名和密码
out_pass() {
    color_echo $GREEN "用户名: admin"
    color_echo $GREEN "初始密码: ${ARLRANDOM_PASS}"
}

# 添加指纹功能
add_finger() {
    local download_dir="/opt/ARL/misc"
    local target_url="https://127.0.0.1:5003/"
    local admin_user="admin"
    local admin_pass="arlpass"
    local method="old"
    local finger_file="$download_dir/finger.json"
    local script_url="$ADD_FINGER_SCRIPT_URL"  # 指纹添加脚本的 URL (已定义为全局变量)
    local finger_url="$DEFAULT_FINGER_URL"  # 指纹文件的URL (已定义为全局变量)

    # 检查 /opt/ARL/misc 目录，如果不存在则使用 /root
    if [ ! -d /opt/ARL/misc ]; then
        color_echo $YELLOW "/opt/ARL/misc 目录不存在，将使用 /root 作为下载目录。"
        download_dir="/root"
    fi
   
    # 用户交互：获取目标 URL
    read -r -p "请输入目标 URL (默认: ${target_url}): " user_input
    target_url="${user_input:-$target_url}"

    # 用户交互：获取管理员用户名和密码
    read -r -p "请输入管理员用户名 (默认: ${admin_user}): " user_input
    admin_user="${user_input:-$admin_user}"
    read -r -p "请输入管理员密码 (默认: ${admin_pass}): " user_input
    admin_pass="${user_input:-$admin_pass}"

    # 用户交互：选择添加方式
    print_separator "-" 30
    echo "请选择指纹添加方式:"
    echo "1. old - 旧方式：逐条添加指纹（适合已有 JSON 数据）"
    echo "   格式示例:"
    echo '     { "cms": "致远OA", "method": "keyword", "location": "rule: body", "keyword": ["/seeyon/USER-DATA/IMAGES/LOGIN/login.gif"] }'
    echo "2. new - 新方式：批量上传指纹文件（适合导入大批量指纹）"
    echo "   格式示例:"
    echo '      - name: 致远OA'
    echo '        rule: body="/seeyon/USER-DATA/IMAGES/LOGIN/login.gif"'
    print_separator "-" 30
    read -r -p "请输入选择的添加方式 (new 或 old，默认: ${method}): " user_input
    method="${user_input:-$method}"
  
    # 用户交互: 指纹文件路径
    read -r -p "请输入指纹文件路径 (例如：/opt/ARL/misc/finger.json，留空则使用默认的 ${finger_file}): " user_input
    finger_file="${user_input:-$finger_file}"
  

    # 下载指纹添加脚本 (如果不存在)
    if [ ! -s "$download_dir/ADD-ARL-Finger.py" ]; then
        color_echo $YELLOW "ADD-ARL-Finger.py 不存在，正在下载..."
         download_file "$script_url" "$download_dir/ADD-ARL-Finger.py"
    fi

    # 下载指纹文件 (如果不存在 或 用户指定了新路径)
    if [ ! -s "$finger_file" ]; then
         color_echo $YELLOW "指纹文件 $finger_file 不存在, 正在下载..."
         download_file "$finger_url" "$finger_file"
    fi


    # 检查 Python 命令 (优先 python3.6)
    local python_cmd="python3"
    if command -v python3.6 &>/dev/null; then
        python_cmd="python3.6"
    fi


    # 执行指纹添加
    color_echo $GREEN "开始添加指纹 (使用文件路径: $finger_file)..."
    "$python_cmd" "$download_dir/ADD-ARL-Finger.py" "$target_url" "$admin_user" "$admin_pass" "$method" "$finger_file"
     if [ $? -eq 0 ];then
        color_echo $GREEN "指纹添加完成。"
     else
       color_echo $RED "指纹添加过程出现错误，请查看日志。"
     fi
}

# 切换镜像源 (使用清华大学开源软件镜像站)
sources_shell() {
    color_echo $YELLOW "开始切换镜像源 (使用LinuxMirrors)..."
    color_echo $YELLOW "https://github.com/SuperManito/LinuxMirrors"
    local mirrors_script="/opt/ChangeMirrors.sh"
    local script_url="https://linuxmirrors.cn/main.sh"

    if [ ! -f "$mirrors_script" ]; then
        color_echo $YELLOW "下载 ChangeMirrors.sh 脚本..."
        download_file "$script_url" "$mirrors_script"
    fi

    if [ -f "$mirrors_script" ]; then
        bash "$mirrors_script"
        color_echo $GREEN "镜像源切换完成。"
    else
        color_echo $RED "镜像源切换失败，请检查网络连接或手动配置。"
    fi
}

# 检查并关闭 SELinux 和防火墙
check_selinux() {
    # 禁用防火墙
    for service in firewalld iptables; do
        if systemctl is-enabled "$service" &>/dev/null; then
            sudo systemctl stop "$service" &>/dev/null
            sudo systemctl disable "$service" &>/dev/null
            color_echo $YELLOW "防火墙 $service 已禁用."
        fi
    done
    # 禁用 ufw (如果存在)
    if command -v ufw &> /dev/null; then
        sudo ufw disable &> /dev/null
        color_echo $YELLOW "防火墙 ufw 已禁用."
    fi

    # 检查并禁用 SELinux
    if sestatus &>/dev/null && sestatus | grep "SELinux status" | grep -q "enabled"; then
        color_echo $YELLOW "SELinux 已启用，正在禁用..."
        sudo setenforce 0
        sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        color_echo $GREEN "SELinux 已禁用."
    else
        color_echo $GREEN "SELinux 已禁用或未安装。"
    fi
}

# 检测操作系统版本 (更精确的匹配)
fixed_check_osver() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        color_echo $RED "无法确定发行版。"
        exit 1
    fi

    # 使用 case 语句进行更精确的匹配
    case "$ID$VERSION_ID" in
        centos7)
            os_ver="CentOS Linux 7"
            ;;
        centos8|rhel8|rocky8.10)  # 兼容 CentOS 8 RHEL 8 Rocky 8.10
            os_ver="CentOS/RHEL 8/Rocky 8.10"
            ;;
        ubuntu20.04)
            os_ver="Ubuntu 20.04"
            ;;
        *)
            color_echo $RED "此脚本目前不支持您的系统: $NAME $VERSION_ID"
            exit 1
            ;;
    esac
    color_echo $GREEN "检测到操作系统: $os_ver"
}

# 检查并安装指定版本的 PyYAML
check_and_install_pyyaml() {
    local required_version="5.4.1"
    local installed_version

    # 检查 python3.6 是否存在, 如果不存在则使用 python3
    if command -v python3.6 &> /dev/null; then
        installed_version=$(pip3.6 show PyYAML | grep Version | cut -d ' ' -f 2)
    elif command -v python3 &> /dev/null; then
        installed_version=$(pip3 show PyYAML | grep Version | cut -d ' ' -f 2)
    else
        color_echo $RED "错误：未找到 python3.6 或 python3。"
        exit 1
    fi

    if [ "$installed_version" != "$required_version" ]; then
         color_echo $YELLOW "正在安装 PyYAML 版本 $required_version ..."
        if command -v python3.6 &> /dev/null; then
            pip3.6 install --ignore-installed PyYAML=="$required_version"
        else
            pip3 install --ignore-installed PyYAML=="$required_version"
        fi
    else
        color_echo $GREEN "PyYAML 版本 $required_version 已安装。"
    fi
}

# 检查并添加 Nginx 日志格式配置
add_check_nginx_log_format() {
    local NGINX_CONF="/etc/nginx/nginx.conf"
    local NEW_CONF="/opt/ARL/misc/nginx.conf"

    # 检查 log_format 是否已存在
    if grep -q 'log_format main' "$NGINX_CONF"; then
        color_echo $GREEN "Nginx 日志格式已配置，无需修改。"
    else
        color_echo $YELLOW "Nginx 日志格式未配置，正在添加..."
        # 备份并替换配置文件
        sudo cp "$NGINX_CONF" "${NGINX_CONF}.bak"
        sudo cp "$NEW_CONF" "$NGINX_CONF"
        color_echo $GREEN "Nginx 配置文件已更新。"
    fi
}

# 安装 ARL 的通用步骤 (适用于所有环境和发行版)
install_arl_common() {
    # 启动服务
    for svc in mongod rabbitmq-server; do
        sudo systemctl enable "$svc"
        sudo systemctl start "$svc"
    done

    # 克隆 ARL 和 ARL-NPoC (根据网络环境选择源)
    local arl_repo="https://github.com/SurrealSky/ARL"
    local arl_npoc_repo="https://github.com/SurrealSky/ARL-NPoC"

    if is_cn_env; then
        arl_repo="https://gitee.com/SurrealSky/ARL"
        arl_npoc_repo="https://gitee.com/SurrealSky/ARL-NPoC"
    fi

    if [ ! -d "$ARL_DIR" ]; then
        color_echo $YELLOW "克隆 ARL 项目..."
        git clone "$arl_repo" "$ARL_DIR"
    fi

    if [ ! -d "$ARL_NPoC_DIR" ]; then
        color_echo $YELLOW "克隆 ARL-NPoC 项目..."
        git clone "$arl_npoc_repo" "$ARL_NPoC_DIR"
    fi
    #检测PYYAML是否安装为其他版本
    check_and_install_pyyaml

    # 安装 ARL-NPoC 的依赖
    cd "$ARL_NPoC_DIR" || exit
    color_echo $YELLOW "安装 ARL-NPoC 依赖..."
    pip3.6 install -r requirements.txt
    pip3.6 install -e .
    cd "$BASE_DIR" || exit

    # 安装 ncrack、GeoLite2
    install_ncrack
    download_geolite2

    # 配置 ARL
    cd "$ARL_DIR" || exit
    if [ ! -f rabbitmq_user ]; then
        color_echo $YELLOW "配置 RabbitMQ 用户..."
        rabbitmqctl add_user arl arlpassword
        rabbitmqctl add_vhost arlv2host
        rabbitmqctl set_user_tags arl arltag
        rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
        color_echo $YELLOW "初始化 ARL 用户..."
        rand_pass  # 生成随机密码并创建 mongo-init.js
        mongo 127.0.0.1:27017/arl docker/mongo-init.js
        touch rabbitmq_user
    fi

    color_echo $YELLOW "安装 ARL 依赖..."
    pip3.6 install -r requirements.txt
    if [ ! -f app/config.yaml ]; then
        color_echo $YELLOW "创建 ARL 配置文件..."
        cp app/config.yaml.example app/config.yaml
    fi
    if [ ! -f /usr/bin/phantomjs ]; then
        color_echo $YELLOW "安装 phantomjs..."
        sudo ln -s "$(pwd)"/app/tools/phantomjs /usr/bin/phantomjs
    fi
    
    # 根据系统类型配置nginx
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        add_check_nginx_log_format
         if [ ! -f /etc/nginx/sites-available/arl.conf ]; then
            color_echo $YELLOW "复制 ARL Nginx 配置..."
            sudo cp misc/arl.conf /etc/nginx/sites-available/
            sudo ln -s /etc/nginx/sites-available/arl.conf /etc/nginx/sites-enabled/
         fi
    elif [[ -f /etc/redhat-release || -f /etc/fedora-release ]]; then
        # CentOS/RHEL/Fedora
        if [ ! -f /etc/nginx/conf.d/arl.conf ]; then
            color_echo $YELLOW "复制 ARL Nginx 配置..."
            sudo cp misc/arl.conf /etc/nginx/conf.d/
        fi
    fi

    if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
        color_echo $YELLOW "下载 dhparam.pem..."
        curl -s https://ssl-config.mozilla.org/ffdhe2048.txt | sudo tee /etc/ssl/certs/dhparam.pem > /dev/null
    fi

    color_echo $YELLOW "生成证书..."
    chmod +x ./docker/worker/gen_crt.sh
    ./docker/worker/gen_crt.sh

    # 复制 systemd 服务文件
    for service_file in arl-web arl-worker arl-worker-github arl-scheduler; do
        if [ ! -f "/etc/systemd/system/$service_file.service" ]; then
            color_echo $YELLOW "复制 $service_file 服务文件..."
            sudo cp "misc/$service_file.service" /etc/systemd/system/
        fi
    done

    # 重新加载 systemd 配置
    sudo systemctl daemon-reload

   # 启动 ARL 服务
    color_echo $YELLOW "启动 ARL 服务..."
    for service in arl-web arl-worker arl-worker-github arl-scheduler nginx; do
        sudo systemctl enable "$service"
        sudo systemctl restart "$service" # 使用 restart, 确保服务最新
    done
    
    # 启动并检查 MongoDB 和 RabbitMQ 服务状态
    for service in mongod rabbitmq-server; do
        sudo systemctl restart "$service"
        sudo systemctl --no-pager status "$service"
    done

    # 检查并启动 ARL 相关服务状态
    for service in arl-web arl-worker arl-worker-github arl-scheduler anginx; do
        sudo systemctl restart "$service"
        sudo systemctl --no-pager status "$service"
    done

    color_echo $GREEN "ARL 安装完成！"
}

# CentOS 7 源码安装
install_for_centos() {
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR" || exit

    # 配置 MongoDB 源
    local mongodb_config=$(get_mongodb_repo_config centos 7)
    echo "$mongodb_config" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo

    # 安装依赖
    color_echo $YELLOW "安装依赖..."
    sudo yum install epel-release -y
    sudo yum clean all
    sudo yum makecache
    sudo yum install -y python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git nginx fontconfig wqy-microhei-fonts unzip wget

    # 链接 python3.6 
    if [ ! -f /usr/bin/python3.6 ]; then
        color_echo $YELLOW "链接 python3.6..."
        sudo ln -s /usr/bin/python36 /usr/bin/python3.6
    fi

    # 安装 pip3.6 
    install_pip36

    # 安装 nmap,nuclei,wih
    install_nmap
    install_nuclei
    install_wih

    # 安装 ARL (通用步骤)
    install_arl_common
}

# CentOS 8 源码安装
install_for_centos8() {
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR" || exit
    # 配置 MongoDB 源
    local mongodb_config=$(get_mongodb_repo_config centos 8)
    echo "$mongodb_config" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo

    # 配置 RabbitMQ 源
    local rabbitmq_config=$(get_rabbitmq_repo_config centos 8)
    echo "$rabbitmq_config" | sudo tee /etc/yum.repos.d/rabbitmq.repo

    # 安装依赖
    color_echo $YELLOW "安装依赖..."
    sudo yum install epel-release -y
    sudo yum clean all
    sudo yum makecache
    sudo yum install -y python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git nginx fontconfig wqy-microhei-fonts unzip wget

    # 链接 python3.6 (如果需要)
    if [ ! -f /usr/bin/python3.6 ]; then
        color_echo $YELLOW "链接 python3.6..."
        sudo ln -s /usr/bin/python36 /usr/bin/python3.6
    fi
    
    # 安装 pip3.6
    install_pip36

    # 安装 nmap、nuclei、wih
    install_nmap
    install_nuclei
    install_wih
    
    # 安装 ARL (通用步骤)
    install_arl_common
}

# Ubuntu 20.04 源码安装
install_for_ubuntu() {
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR" || exit

    # 添加 MongoDB 源
    if ! command -v curl &> /dev/null; then
        color_echo $YELLOW "安装 curl ..."
        sudo apt-get install curl -y
    fi

    sudo apt-get update -y &&  sudo apt-get install -y gnupg
    curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

    local mongodb_config=$(get_mongodb_repo_config ubuntu 20.04)
    echo "$mongodb_config" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

    # 安装依赖
    color_echo $YELLOW "安装依赖..."
    sudo apt-get update
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get update
    sudo apt-get install -y python3.6 mongodb-org rabbitmq-server python3.6-dev g++ git nginx fontconfig unzip wget  python3.6-distutils
    
    # 安装 pip3.6
    install_pip36
   
    # 安装 nmap、nuclei、wih
    install_nmap
    install_nuclei
    install_wih
    
    # 安装 ARL (通用步骤)
    install_arl_common
}

# 源码安装 (根据操作系统和网络环境自动选择)
code_install() {
    fixed_check_osver # 检查操作系统

    case "$os_ver" in
    "CentOS Linux 7")
        check_selinux
        install_for_centos
        ;;
    "CentOS/RHEL 8/Rocky 8.10")
        check_selinux
        install_for_centos8
        ;;
    "Ubuntu 20.04")
        install_for_ubuntu
        ;;
    *)
        color_echo $RED "不支持的操作系统：$os_ver"
        exit 1
        ;;
    esac
}

# 主菜单
main_menu() {
    clear
    print_separator
    color_echo $BLUE "ARL 自动化部署脚本 (版本 $ARL_VERSION)"
    print_separator
    echo "首次安装建议先进行换源操作。"
    echo "1) 切换镜像源 (使用LinuxMirrors)"
    echo "2) 源码安装 (支持 CentOS 7/8, Ubuntu 20.04, 区分国内外环境)"
    echo "3) 添加指纹 (默认 7k+ 指纹, 仅限源码安装)"
    echo "4) 安装ARL管理面板"
    echo "5) 退出脚本"
    print_separator
    read -r -p "请输入对应数字: " code_id

    case "$code_id" in
    1)  # 换源
        sources_shell
        main_menu
        ;;
    2)  # 源码安装
        code_install
        manage_arl
        ipinfo
        out_pass          
        ;;
    3)  # 添加指纹
        add_finger
        ;;
    4)  # 安装面板
        manage_arl
        ;;
    5)  # 退出
        exit 0
        ;;
    *)
        color_echo $RED "无效选项，请重新输入。"
        sleep 2
        main_menu
        ;;
    esac
}

# 开始执行
check_and_install_git
main_menu