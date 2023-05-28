#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config-openwrt/imagebuilder/imagebuilder.sh <source:branch>
#          ./config-openwrt/imagebuilder/imagebuilder.sh openwrt:21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config-openwrt/imagebuilder/files"
custom_config_file="${make_path}/config-openwrt/imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Downloading imagebuilder files
    if [[ "${op_sourse}" == "openwrt" ]]; then
        download_file="https://downloads.openwrt.org/releases/${op_branch}/targets/armvirt/64/openwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    else
        download_file="https://downloads.immortalwrt.org/releases/${op_branch}/targets/armvirt/64/immortalwrt-imagebuilder-${op_branch}-armvirt-64.Linux-x86_64.tar.xz"
    fi
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf *-imagebuilder-* && sync && rm -f *-imagebuilder-*.tar.xz
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start adding custom packages..."
    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-openclash
    OC_Version=$(curl -sL https://github.com/vernesong/OpenClash/tags |
        grep 'v0.45.' |
        sed -e 's/\"//g' -e 's/ //g' -e 's/rel=.*//g' -e 's#<ahref=##g' -e 's/>//g' -e 's#/vernesong/OpenClash/releases/tag/##g' -e 's/v//g' -e 's#<aclass=Link--mutedhref=##g' -e 's/>//g' |
        awk 'FNR == 4')
    OC_Luci="https://github.com/vernesong/OpenClash/releases/download/v${OC_Version}/luci-app-openclash_${OC_Version}_all.ipk"
    wget -q -P packages/ ${OC_Luci}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${OC_Luci} ] is downloaded successfully."
    # Add Requirements for OpenClash
    echo "src luci-app-openclash file:packages" >> repositories.conf
    cat >>packages.txt << EOF

coreutils
coreutils-nohup
iptables-mod-tproxy
iptables-mod-extra
libcap
libcap-bin
ruby
ruby-yaml
ip6tables-mod-nat
luci-app-openclash
EOF
    # Add Requirements for TinyFileManager
    cat >>packages.txt <<EOL

php8 
php8-cgi 
php8-fastcgi 
php8-fpm 
php8-mod-session 
php8-mod-ctype 
php8-mod-fileinfo 
php8-mod-zip 
php8-mod-iconv 
php8-mod-mbstring 
coreutils-stat 
zoneinfo-asia 
bash 
curl 
tar
EOL
    # Add tano theme
    Tano_Repo="https://github.com/jakues/luci-theme-tano/releases/download/0.1/luci-theme-tano_0.1_all.ipk"
    wget -q -P packages/ ${Tano_Repo}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${Tano_Repo} ] is downloaded successfully."
    echo "src luci-theme-tano file:packages" >> repositories.conf

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}

    [[ -d "${custom_files_path}" ]] && {
        echo -e "${STEPS} Start adding custom files..."
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files
        #
        # custom files here
        #
        # Change Permission neofetch and other
        chmod +x files/usr/bin/neofetch files/usr/bin/hilink files/etc/zshinit || error_msg "Please check the path file"
        sed -i -e "s/4.3.2.1/${addr}/g" files/etc/config/network
        # Clone OhMyZsh
        OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
        git clone -q ${OMZ_REPO} files/root/.oh-my-zsh
        # Add Additional Custom Repo's
        # Disable Signature Verification
        sed -i 's/option check_signature/# option check_signature/g' repositories.conf
        # Add Repo 21.02.3 packages
        echo "src/gz old_packages_repos https://downloads.openwrt.org/releases/21.02.3/packages/${ARCH}/packages/" >> repositories.conf
        # Add Repo 21.02.3 base
        echo "src/gz old_base_repos https://downloads.openwrt.org/releases/21.02.3/packages/${ARCH}/base/" >> repositories.conf
        # Add lrdrdn Generic repo
        echo "src/gz custom_generic https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/generic" >> repositories.conf
        # Add lrdrdn Architecture repo
        echo "src/gz custom_arch https://raw.githubusercontent.com/lrdrdn/my-opkg-repo/main/${ARCH}" >> repositories.conf
        #
        # Install Core Clash
        OC_Core_Dir="files/etc/openclash/core"
        OC_Core_Repo="https://raw.githubusercontent.com/vernesong/OpenClash/master/core-lateset"
        OC_Premium_Version=$(echo $(curl -sL https://github.com/vernesong/OpenClash/raw/master/core_version | awk '{print $1}') | awk '{print $2}')
        mkdir -p ${OC_Core_Dir}
        # Core Meta
        # example https://github.com/vernesong/OpenClash/raw/master/core-lateset/meta/clash-linux-armv7.tar.gz
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/meta/clash-linux-${SHORT_ARCH}.tar.gz || error_msg "Failed to download OpenClash Core"
        tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error_msg "Failed to install OpenClash Core"
        mv files/etc/openclash/core/clash files/etc/openclash/core/clash_meta || error_msg "Failed to rename clash_meta"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
        # Core Premium
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/premium/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error_msg "Failed to download OpenClash Core"
        gzip -dk ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz || error_msg "Failed to install OpenClash Core"
        mv ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version} files/etc/openclash/core/clash_tun || error_msg "Failed to rename clash_tun"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}-${OC_Premium_Version}.gz
        # Core Dev
        wget -q -P ${OC_Core_Dir} ${OC_Core_Repo}/dev/clash-linux-${SHORT_ARCH}.tar.gz || error_msg "Failed to download OpenClash Core"
        tar -xf ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz -C ${OC_Core_Dir} || error_msg "Failed to install OpenClash Core"
        rm ${OC_Core_Dir}/clash-linux-${SHORT_ARCH}.tar.gz
        #
        # Install TinyFileManager
        TFM_Repo="https://github.com/jakues/tinyfilemanager/raw/master/tinyfilemanager.php"
        TFM_Conf="https://github.com/jakues/tinyfilemanager/raw/master/config-sample.php"
        TFM_Dir="files/www"
        wget -q -P ${TFM_Dir} ${TFM_Repo} || error_msg "Cant download tiny file manager"
        wget -q -O ${TFM_Dir}/config.php ${TFM_Conf} || error_msg "Cant download tiny file manager config"
        sed -i -e 's/$use_auth = true;/$use_auth = false;/g' \
            -e 's#Etc/UTC#Asia/Jakarta#g' \
            -e 's/?>//g' \
            -e 's#$root_path*#// $root_path*#g' ${TFM_Dir}/config.php
        cat >>${TFM_Dir}/config.php <<EOI

root_path = '../'

?>
EOI
        sed -i -e 's#root_path#$root_path#g' ${TFM_Dir}/config.php
        TFM_Lua_Dir="files/usr/lib/lua/luci/controller"
        TFM_Html_Dir="files/usr/lib/lua/luci/view"
        mkdir -p ${TFM_Lua_Dir}
        cat >${TFM_Lua_Dir}/tinyfm.lua <<EOF
module("luci.controller.tinyfm", package.seeall)
function index()
entry({"admin","system","tinyfm"}, template("tinyfm"), _("File Explorer"), 55).leaf=true
end
EOF
        mkdir -p ${TFM_Html_Dir}
        cat >${TFM_Html_Dir}/tinyfm.htm <<EOL
<%+header%>
<div class="cbi-map">
<br>
<iframe id="tinyfm" style="width: 100%; min-height: 650px; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("tinyfm").src = "http://" + window.location.hostname + "/tinyfilemanager.php";
</script>
<%+footer%>
EOL

        # Set tano theme on branch 21.+
        if [[ ${rebuild_branch} = 21.* || ${rebuild_branch} = 22.* ]] ; then
            cat > files/etc/uci-defaults/30_luci-theme-tano << EOL
#!/bin/sh

	uci get luci.themes.Tano >/dev/null 2>&1 || \
	uci batch <<-EOF
		set luci.themes.Tano=/luci-static/tano
		set luci.main.mediaurlbase=/luci-static/tano
		commit luci
	EOF

exit 0
EOL
        fi

        # Set brcm-userland for old branch
        

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    }
}
# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    # sorting by https://build.moz.one
    my_packages="\
        acpid attr base-files bash bc blkid block-mount blockd bsdtar \
        btrfs-progs busybox bzip2 cgi-io chattr comgt comgt-ncm containerd coremark \
        coreutils coreutils-base64 coreutils-nohup coreutils-truncate curl docker \
        docker-compose dockerd dosfstools dumpe2fs e2freefrag e2fsprogs exfat-mkfs \
        f2fs-tools f2fsck fdisk gawk getopt gzip hostapd-common iconv iw iwinfo jq jshn \
        kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-mac80211 libjson-script \
        liblucihttp liblucihttp-lua libnetwork losetup lsattr lsblk lscpu mkf2fs \
        mount-utils openssl-util parted perl-http-date perlbase-file perlbase-getopt \
        perlbase-time perlbase-unicode perlbase-utf8 pigz ppp ppp-mod-pppoe \
        proto-bonding pv rename resize2fs runc subversion-client subversion-libs tar \
        tini ttyd tune2fs uclient-fetch uhttpd uhttpd-mod-ubus unzip uqmi usb-modeswitch \
        uuidgen wget-ssl whereis which wpad-basic wwan xfs-fsck xfs-mkfs xz \
        xz-utils ziptool zoneinfo-asia zoneinfo-core zstd \
        \
        luci luci-base luci-compat luci-i18n-base-en luci-i18n-base-zh-cn luci-lib-base  \
        luci-lib-docker luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio  \
        luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system  \
        luci-proto-3g luci-proto-bonding luci-proto-ipip luci-proto-ipv6 luci-proto-ncm  \
        luci-proto-openconnect luci-proto-ppp luci-proto-qmi luci-proto-relay  \
        \
        luci-app-amlogic luci-i18n-amlogic-zh-cn \
        \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}" FILES="files"

    sync && sleep 3
    echo -e "${INFO} [ openwrt/bin/targets/armvirt/64 ] directory status: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} openwrt:22.03.3 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Incoming parameter format <source:branch>: openwrt:22.03.3"
op_sourse="${1%:*}"
op_branch="${1#*:}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild Source: [ ${op_sourse} ], Branch: [ ${op_branch} ]"
echo -e "${INFO} Server space usage before starting to compile: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
