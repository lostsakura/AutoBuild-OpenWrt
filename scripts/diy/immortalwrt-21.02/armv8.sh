#!/bin/bash

# 修改默认IP和hostname
sed -i 's/192.168.1.1/10.10.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 修改opkg源
echo "src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/aarch64_cortex-a53/kiddin9" >> package/system/opkg/files/customfeeds.conf

rm_package() {
    find ./ -maxdepth 4 -iname "$1" -type d | xargs rm -rf || echo -e "\e[31mNot found [$1]\e[0m"
}

rm_package "*alist"
rm_package "*ddns-go"
rm_package "*smartdns"
rm_package "*sqm*"
rm_package "minidlna"
rm_package "miniupnpd"
rm_package "zerotier"

git_sparse_clone() {
    branch="$1" repourl="$2" repodir="$3"
    [[ -d "package/cache" ]] && rm -rf package/cache
    git clone -q --branch=$branch --depth=1 --filter=blob:none --sparse $repourl package/cache &&
    git -C package/cache sparse-checkout set $repodir &&
    mv -f package/cache/$repodir package &&
    rm -rf package/cache ||
    echo -e "\e[31mFailed to sparse clone $repodir from $repourl($branch).\e[0m"
}

git_sparse_clone master https://github.com/immortalwrt/luci.git applications/luci-app-alist
git_sparse_clone master https://github.com/immortalwrt/luci.git applications/luci-app-ddns-go
git_sparse_clone master https://github.com/immortalwrt/luci.git applications/luci-app-minidlna
git_sparse_clone master https://github.com/immortalwrt/luci.git applications/luci-app-smartdns
git_sparse_clone master https://github.com/immortalwrt/luci.git applications/luci-app-sqm
git_sparse_clone master https://github.com/immortalwrt/packages.git multimedia/minidlna
git_sparse_clone master https://github.com/immortalwrt/packages.git net/alist
git_sparse_clone master https://github.com/immortalwrt/packages.git net/ddns-go
git_sparse_clone master https://github.com/immortalwrt/packages.git net/miniupnpd
git_sparse_clone master https://github.com/immortalwrt/packages.git net/smartdns
git_sparse_clone master https://github.com/immortalwrt/packages.git net/sqm-scripts
git_sparse_clone master https://github.com/immortalwrt/packages.git net/zerotier

find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

sed -i 's|admin/network|admin/control|g' package/luci-app-sqm/root/usr/share/luci/menu.d/*.json

replace_text() {
  search_text="$1" new_text="$2"
  sed -i "s/$search_text/$new_text/g" $(grep "$search_text" -rl ./ 2>/dev/null) || echo -e "\e[31mNot found [$search_text]\e[0m"
}

replace_text "DDNS-Go" "DDNSGO"
replace_text "SQM QoS" "SQM管理"
replace_text "SQM 队列管理" "SQM管理"

echo -e "\e[32m$0 [DONE]\e[0m"