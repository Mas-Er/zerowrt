#!/usr/bin/bash
#!/usr/bin/zsh

# Set Variable
export PRIN="printf"
export ECMD="echo -e"
export CR='\e[0m'
export COL_LIGHT_GREEN='\e[1;32m'
export COL_LIGHT_RED='\e[1;31m'
export TICK="[${COL_LIGHT_GREEN}✓${CR}]"
export CROSS="[${COL_LIGHT_RED}✗${CR}]"
export INFO="[i]"
export QST="[?]"
export DONE="${COL_LIGHT_GREEN} done !${CR}"
export SLP="sleep 0.69s"
export R=20
export C=70
export OPENWRT_ORIGINAL_URL="https://downloads.openwrt.org/releases"
# export OPENWRT_RASPI="bcm27xx"
# export OPENWRT_RASPI_OLD="brcm2708"
# V2ray Version
# export V2RAY_VERSION="4.41.1-1"

error() {
    ${PRIN} "$1 ! ${CROSS}"
    exit
}

# Select OpenWrt version from official repository
OPENWRT_VERSION () {
    DIALOG_VERSION=$(whiptail --title "Openwrt Version" \
		--radiolist "Choose your version" ${R} ${C} 3 \
		"21.02.1" "Latest Stable Release" ON \
		"19.07.8" "Old Stable Release" OFF \
		"18.06.9" "Old Stable Archive"  OFF \
    3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
        export OPENWRT_VERZION=${DIALOG_VERSION}
    else
        error "Operation Canceled"
    fi

	if [[ ${DIALOG_VERSION} = 19.* ]] ; then
		export OPENWRT_RASPI="brcm2708"
	elif [[ ${DIALOG_VERSION} = 18.* ]] ; then
		export OPENWRT_RASPI="brcm2708"
	elif [[ ${DIALOG_VERSION} = 21.* ]] ; then
		export OPENWRT_RASPI="bcm27xx"
	fi
}


# Select Raspberry Pi Model
OPENWRT_MODEL () {
	export MODEL_1="Pi 1 (32 bit) compatible on pi 0,0w,1B,1B+"
	export MODEL_2="Pi 2 (32 bit) compatible on pi 2B,2B+,3B,3B+,CM3"
	export MODEL_3="Pi 3 (64 bit) compatible on pi 2Brev2,3B,3B+,CM3"
	export MODEL_4="Pi 4 (64 bit) compatible on pi 4B,CM4"

    whiptail --title "Raspberry Pi Model" \
		--radiolist "Choose your raspi model" ${R} ${C} 4 \
		"bcm2708" "${MODEL_1}" ON \
		"bcm2709" "${MODEL_2}"  OFF \
		"bcm2710" "${MODEL_3}"  OFF \
		"bcm2711" "${MODEL_4}"  OFF \
		2>model.txt

    if [ $? = 0 ] ; then
        export MODEL_ARCH=$(cat model.txt)
    else
        OPENWRT_VERSION
    fi

    if [[ ${MODEL_ARCH} = bcm2708 ]] ; then
        export INFO_MODEL="rpi"
        export ARCH="arm_arm1176jzf-s_vfp"
        export AKA_ARCH="arm32-v6"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_1}"
    elif [[ ${MODEL_ARCH} = bcm2709 ]] ; then
		export INFO_MODEL="rpi-2"
        export ARCH="arm_cortex-a7_neon-vfpv4"
        export AKA_ARCH="arm32-v7a"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_2}"
	elif [[ ${MODEL_ARCH} = bcm2710 ]] ; then
		export INFO_MODEL="rpi-3"
		export ARCH="aarch64_cortex-a53"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="arm64"
        export MODELL="${MODEL_3}"
	elif [[ ${MODEL_ARCH} = bcm2711 ]] ; then
		export INFO_MODEL="rpi-4"
		export ARCH="aarch64_cortex-a72"
        export AKA_ARCH="arm64-v8a"
        export SHORT_ARCH="arm"
        export MODELL="${MODEL_4}"
	fi

}

OPENWRT_BOOTFS () {
	DIALOG_BOOT=$(whiptail --title "Set partition size of /boot" \
        --inputbox "Write size of /boot [>30 Mb] :" ${R} ${C} "30" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
        # echo "Size of /boot partition : ${DIALOG_BOOT} Mb"
		export BOOTFS=${DIALOG_BOOT}
    else
        OPENWRT_MODEL
    fi
}

OPENWRT_ROOTFS () {
	DIALOG_ROOT=$(whiptail --title "Set partition size of /root" \
        --inputbox "Write size of /root [>300 Mb] :" ${R} ${C} "300" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export ROOTFS=${DIALOG_ROOT}
    else
        OPENWRT_BOOTFS
    fi
}

OPENWRT_IPADDR () {
	DIALOG_IPADDR=$(whiptail --title "Set default ip address" \
        --inputbox "Write ip address openwrt :" ${R} ${C} "192.168.1.1" \
        3>&1 1>&2 2>&3)

    if [ $? = 0 ] ; then
		export IP_ADDR=${DIALOG_IPADDR}
    else
        OPENWRT_ROOTFS
    fi
}

OPENWRT_TUNNEL () {
    whiptail --title "Select tunnel package" \
		--checklist --separate-output "Choose your package" ${R} ${C} 4 \
		"Openclash" "" OFF \
		"Openvpn" ""  OFF \
		"Wireguard" ""  OFF \
		"Xderm" ""  OFF \
		2>tunnel.txt

    while read dTunnel ; do
        case "$dTunnel" in
            Openclash)
                Openclash
            ;;
            Openvpn)
                Openvpn
            ;;
            Wireguard)
                Wireguard
            ;;
            Xderm)
                Xderm
            ;;
            *)
            ;;
        esac
    done < tunnel.txt
}

# Preparation before cooking ZeroWrt
OPENWRT_PREPARE () {
export IMAGEBUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERZION}-${OPENWRT_RASPI}-${MODEL_ARCH}.Linux-x86_64"
export IMAGEBUILDER_FILE="${IMAGEBUILDER_DIR}.tar.xz"
export IMAGEBUILDER_URL="${OPENWRT_ORIGINAL_URL}/${OPENWRT_VERZION}/targets/${OPENWRT_RASPI}/${MODEL_ARCH}/${IMAGEBUILDER_FILE}"
export ROOT_DIR="${IMAGEBUILDER_DIR}/files"
export HOME_DIR="${ROOT_DIR}/root"
    # Prepare imagebuilder
    ${PRIN} " %b %s ... " "${INFO}" "Downloading Imagebuilder"
    	wget -q ${IMAGEBUILDER_URL} || error "Failed to download imagebuilder !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Extracting Imagebuilder"
        tar xf ${IMAGEBUILDER_FILE} || error "Failed to extract file !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Removing Imagebuilder"
        rm ${IMAGEBUILDER_FILE} || error "Failed to remove file !"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # ${PRIN} " %b %s ... " "${INFO}" "Preparing requirements"
    #     #cp $(pwd)/${DIR_TYPE}/disabled.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:disabled.txt !"
    #     #cp $(pwd)/${DIR_TYPE}/packages.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:packages.txt !"
        export DIR_TYPE="universal/"
    #     export ZEROWRT_DISABLED="$(echo $(cat $(pwd)/${DIR_TYPE}/disabled.txt))"
        cp $(pwd)/${DIR_TYPE}/packages.txt ${IMAGEBUILDER_DIR} || error "Failed to copy file:packages.txt !"
        export ZEROWRT_PACKAGES="$(echo $(cat $(pwd)/${DIR_TYPE}/packages.txt))"
    # ${SLP}
	# ${PRIN} "%b\\n" "${TICK}"
    # Prepare data
    ${PRIN} " %b %s ... " "${INFO}" "Preparing data"
        mkdir -p ${ROOT_DIR} || error "Failed to create files/root directory !"
        mkdir -p files/usr/lib/lua/luci/controller files/usr/lib/lua/luci/view  || error "Failed to create directory !"
        cp -arf $(pwd)/${DIR_TYPE}/data/* ${ROOT_DIR} || error "Failed to copy data !"
        chmod +x ${ROOT_DIR}/usr/bin/neofetch || error "Failed to chmod:neofetch"
        chmod +x ${ROOT_DIR}/etc/zshinit || error "Failed to chmod:zshinit"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    # Change main directory
    cd ${IMAGEBUILDER_DIR} || error "Failed to change directory !"
    ${PRIN} " %b %s " "${INFO}" "Current directory : $(pwd)"
    ${SLP}
    ${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Configure data"
        sed -i -e "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}/" .config || error "Failed to change bootfs size !"
        sed -i -e "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}/" .config || error "Failed to change rootfs size !"
        sed -i -e "s/4.3.2.1/${IP_ADDR}/" files/etc/config/network || error "Failed to change openwrt ip address"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Installing ohmyzsh"
        export OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
        git clone -q ${OMZ_REPO} files/root/.oh-my-zsh || error "Failed to clone ${OMZ_REPO}"
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
    ${PRIN} " %b %s ... " "${INFO}" "Installing mikhmon"
        export MIKHMON_REPO="https://github.com/laksa19/mikhmonv3.git"
        mkdir -p files/etc/init.d || error "Failed to create dir:init.d"
        git clone -q ${MIKHMON_REPO} files/www/mikhmon || error "Failed to clone ${MIKHMON_REPO}"
        #sed -i 's/str_replace(" ","_",date("Y-m-d H:i:s"))/str_replace(date)/g' files/www/mikhmon/index.php || error "Failed to mod:mikhmon/index.php"
        #sed -i 's/strtolower(date("M"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
        #sed -i 's/strtolowerdate("Y"))/strtolower(date)/g' files/www/mikhmon/include/menu.php || error "Failed to mod:mikhmon/menu.php"
        cat > files/etc/init.d/mikhmon << EOF
#!/bin/sh /etc/rc.common
# Mikhmon init script beta (C) 2021 ZeroWRT
# Copyright (C) 2007 OpenWrt.org

START=69
STOP=01
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command php-cli -S 0.0.0.0:4433 -t /www/mikhmon
	echo "Mikhmon Started"
    procd_close_instance
}

stop_service() {
	kill $(ps | grep 'php-cli -S 0.0.0.0:4433 -t /www/mikhmon' | awk '{print $1}' | awk 'FNR <= 1')
	echo "Mikhmon Stopped"
}

reload_service() {
	if pgrep "php-cli" ; then
	 stop
	 start
	else
	 start	
	fi
}
EOF
    chmod +x files/etc/init.d/mikhmon || error "Failed to chmod file:mikhmon.init"
    cat > files/usr/lib/lua/luci/controller/mikhmon.lua << EOF
module("luci.controller.mikhmon", package.seeall)
function index()
entry({"admin", "services", "mikhmon"}, template("mikhmon"), _("Mikhmon"), 2).leaf=true
end
EOF
        cat > files/usr/lib/lua/luci/view/mikhmon.htm << EOF
<%+header%>
<div class="cbi-map">
<iframe id="mikhmon" style="width: 100%; min-height: 800px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("mikhmon").src = "http://" + window.location.hostname + ":4433";
</script>
<%+footer%>
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Openclash () {
        # Install openclash
        ${PRIN} " %b %s ... " "${INFO}" "Installing OpenClash"
            export OC_REPO=$(curl -sL https://github.com/vernesong/OpenClash/releases \
            | grep 'luci-app-openclash_' \
            | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' \
            | awk 'FNR <= 1')
            wget -q -P packages/ ${OC_REPO} || error "Failed to download file:luci-app-openclash.ipk !"
            ${ECMD} "src luci-app-openclash file:packages" >> repositories.conf
            cat >> packages.txt << EOF
coreutils
coreutils-nohup
iptables-mod-tproxy
iptables-mod-extra
libcap
libcap-bin
ruby
ruby-yaml
ip6tables-mod-nat
EOF
        ${SLP}
	    ${PRIN} "%b\\n" "${TICK}"
}

Openvpn () {
    ${PRIN} " %b %s ... " "${INFO}" "Installing Openvpn"
    cat >> packages.txt << EOF
luci-app-openvpn
openssh-client
openvpn-openssl
openvpn-easy-rsa
stunnel
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Wireguard () {
    ${PRIN} " %b %s ... " "${INFO}" "Installing Openvpn"
    cat >> packages.txt << EOF
kmod-wireguard
luci-app-wireguard
luci-proto-wireguard
wireguard-tools
EOF
    ${SLP}
	${PRIN} "%b\\n" "${TICK}"
}

Xderm () {
    # Install xderm binaries
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing xderm binaries"
        export XDERM_BIN="https://github.com/jakues/libernet-proprietary/raw/main/xderm.txt"
        mkdir -p files/usr/bin
        wget -q ${XDERM_BIN} || error "Failed to download file:binaries.txt !"
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    bin="files/usr/bin/${line}"
                    ${ECMD} "\e[0;34mInstalling\e[0m ${line} ..."
                    wget -q -O "${bin}" "https://github.com/jakues/libernet-proprietary/raw/main/${ARCH}/binaries/${line}" || error "Failed to download xderm binaries !"
                    chmod +x "${bin}" || error "Failed to chmod !"
                    fi
            done < xderm.txt
        mkdir -p packages
        export V2RAY_REPO=$(curl -sL https://github.com/kuoruan/openwrt-v2ray/releases/latest \
        | grep '/kuoruan/openwrt-v2ray/releases/download' \
        | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' \
        | grep 'v2ray-core_' | grep ${ARCH})
        wget -q -P packages/ ${V2RAY_REPO} || error "Failed to download file:v2ray-core.ipk !"
        ${ECMD} "src v2ray-core file:packages" >> repositories.conf
        cat >> packages.txt << EOF
badvpn-tun2socks
coreutils-base64
coreutils-timeout
httping
v2ray-core
procps-ng-ps
python3
python3-pip
openssh-client
openssl-util
php7
php7-cgi
php7-mod-session
https-dns-proxy
EOF
    ${PRIN} " %b %s " "${INFO}" "xderm binaries"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
    ${PRIN} " %b\\n" "${TICK}"
    # Install xderm web
    ${PRIN} " %b %s ... \n" "${INFO}" "Installing xderm webpage"
        export XDERM_REPO="https://github.com/jakues/xderm-mini_GUI/raw/main"
        mkdir -p files/www/xderm files/www/xderm/js files/www/xderm/img files/www/xderm/log
        cat >> xderm << EOF
index.php
index.html
xderm-mini
login.php
header.php
config.txt
EOF
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    xderm_www="files/www/xderm/${line}"
                    ${ECMD} "\e[0;34mDownloading\e[0m ${line} ..."
                    wget -q -O ${xderm_www} ${XDERM_REPO}/${line} || error "Failed to download xderm binaries !"
                    fi
            done < xderm
        cat >> xderm-img << EOF
image.png
fav.ico
ico.png
background.jpg
EOF
            while IFS= read -r line ; do
                    if ! which ${line} > /dev/null 2>&1 ; then
                    xderm_img="files/www/xderm/img/${line}"
                    ${ECMD} "\e[0;34mDownloading\e[0m ${line} ..."
                    wget -q -O ${xderm_img} ${XDERM_REPO}/${line} || error "Failed to download xderm binaries !"
                    fi
            done < xderm-img
        wget -q -P files/www/xderm/js/ ${XDERM_REPO}/jquery-2.1.3.min.js || error "Failed to download xderm binaries !"
        wget -q -P files/usr/bin/ ${XDERM_REPO}/adds/xdrauth || error "Failed to download xderm binaries !"
        wget -q -P files/www/xderm/ ${XDERM_REPO}/adds/xdrtheme-blue-agus || error "Failed to download xderm binaries !"
        wget -q -P files/usr/bin/ ${XDERM_REPO}/adds/xdrtool || error "Failed to download xderm binaries !"
        chmod +x files/usr/bin/xdrauth || error "Faild to change permission"
        chmod +x files/usr/bin/xdrtool || error "Faild to change permission"
        cat > files/usr/lib/lua/luci/controller/xderm.lua << EOF
module("luci.controller.xderm", package.seeall)
function index()
entry({"admin", "services", "xderm"}, template("xderm"), _("Xderm"), 2).leaf=true
end
EOF
        cat > files/usr/lib/lua/luci/view/xderm.htm << EOF
<%+header%>
<div class="cbi-map">
<iframe id="xderm" style="width: 100%; min-height: 800px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("xderm").src = "http://" + window.location.hostname + "/xderm";
</script>
<%+footer%>
EOF
    ${PRIN} " %b %s " "${INFO}" "Install xderm"
    ${PRIN} "%b" "${DONE}"
    ${SLP}
    ${PRIN} " %b\\n" "${TICK}"
}

theme () {
        # Install luci theme edge
        export EDGE_REPO=$(curl -sL https://github.com/kiddin9/luci-theme-edge/releases | grep 'luci-theme-edge_' | sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=#http://github.com#g' | awk 'FNR <= 1')
        wget -q -P packages/ ${EDGE_REPO} || error "Failed to download file:luci-theme-edge.ipk !"
        ${ECMD} "src luci-theme-edge file:packages" >> repositories.conf
        ${ECMD} "luci-theme-edge" >> packages.txt
}

userland () {
    if [[ ${OPENWRT_VERZION} = 19.* && ${OPENWRT_VERZION} = 18.* ]] ; then
		export USERLAND_REPO="https://github.com/jakues/libernet-proprietary/raw/main/${ARCH}/binaries/bcm27xx-userland.ipk"
        ${ECMD} "\e[0;34mInstalling\e[0m bcm27xx-userland ..."
        wget -q -P packages/ ${USERLAND_REPO} || error "Failed to download file:bcm27xx-userland.ipk"
        ${ECMD} "src bcm27xx-userland file:packages" >> repositories.conf
    fi
}

# Cook the image
OPENWRT_BUILD () {
    # Build
    ${PRIN} " %b %s ... \n" "${INFO}" "Ready to cook"
        sleep 2
        make image PROFILE="${INFO_MODEL}" \
        FILES="$(pwd)/files/" \
        EXTRA_IMAGE_NAME="zerowrt-${Ztype}" \
        PACKAGES="${ZEROWRT_PACKAGES}" || error "Failed to build image !"
    #    DISABLED_SERVICES="${ZEROWRT_DISABLED}" || error "Failed to build image !"
    ${PRIN} " %b %s " "${INFO}" "Cleanup"
    # Back to first directory
    cd .. || error "Can't back to working directory !"
    # Store the firmware to ez dir
    mkdir -p results || error "Failed to create directory"
    cp -r ${IMAGEBUILDER_DIR}/bin/targets/${OPENWRT_RASPI}/${MODEL_ARCH} results || error "Failed to store firmware !"
    # Clean up
    rm -rf ${IMAGEBUILDER_DIR} || error "Failed to remove imagebuilder directory !"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Build completed for ${INFO_MODEL}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
    ${PRIN} " %b %s " "${INFO}" "Image stored at : $(pwd)/results/${MODEL_ARCH}"
    ${SLP}
	${PRIN} " %b\\n" "${TICK}"
}

main () {
    OPENWRT_VERSION
    OPENWRT_MODEL
    OPENWRT_BOOTFS
	OPENWRT_ROOTFS
	OPENWRT_IPADDR
    OPENWRT_PREPARE
    # Print info version
        ${PRIN} " %b %s " "${INFO}" "Selected Version : ${OPENWRT_VERZION}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info model
        ${PRIN} " %b %s " "${INFO}" "Selected model: ${INFO_MODEL}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info size bootfs
        ${PRIN} " %b %s " "${INFO}" "CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    # Print info size rootfs
        ${PRIN} " %b %s " "${INFO}" "CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}"
        ${SLP}
        ${PRIN} "%b\\n" "${TICK}"
    OPENWRT_TUNNEL
    userland
    OPENWRT_BUILD
}

main