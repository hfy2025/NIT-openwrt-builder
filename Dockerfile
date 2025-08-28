# 使用官方 OpenWrt Image Builder 镜像（x86-64, OpenWrt 24.10.1）
FROM openwrt/imagebuilder:x86-64-24.10.1

# 设置工作目录
WORKDIR /builder

# 安装必要的工具
RUN opkg update && opkg install git-http ca-bundle

# 添加第三方 feeds（更新分支为 openwrt-24.10）
RUN echo "src-git immortalwrt_luci https://github.com/immortalwrt/luci.git;openwrt-24.10" >> feeds.conf.default && \
    echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git" >> feeds.conf.default && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a

# 复制自定义文件和模块
COPY files /builder/files
COPY modules /builder/modules
COPY custom_modules /builder/custom_modules

# 暴露输出卷
VOLUME /builder/bin
