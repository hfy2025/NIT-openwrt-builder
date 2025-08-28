# 构建脚本
#!/bin/bash

# 加载 .env 文件
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# 默认参数
IMAGE=${IMAGE:-openwrt/imagebuilder:rockchip-armv8-24.10.1}
PROFILE=${PROFILE:-friendlyarm_nanopi-r2s}
OUTPUT_DIR=${OUTPUT_DIR:-./bin}
MIRROR=${MIRROR:-downloads.openwrt.org}
WITH_PULL=${WITH_PULL:-true}
RM_FIRST=${RM_FIRST:-true}
USE_MIRROR=${USE_MIRROR:-false}

# 帮助信息
if [ "$1" == "--help" ]; then
    echo "Usage: ./build.sh [options]"
    echo "Options:"
    echo "  --image=IMAGE         Docker 镜像 (default: $IMAGE)"
    echo "  --profile=PROFILE     设备 profile (default: $PROFILE)"
    echo "  --output=DIR          输出目录 (default: $OUTPUT_DIR)"
    echo "  --mirror=MIRROR       下载镜像 (default: $MIRROR)"
    echo "  --with-pull           拉取最新镜像"
    echo "  --rm-first            先移除旧容器"
    echo "  --use-mirror          使用镜像加速"
    exit 0
fi

# 解析参数
for arg in "$@"; do
    case $arg in
        --image=*) IMAGE="${arg#*=}" ;;
        --profile=*) PROFILE="${arg#*=}" ;;
        --output=*) OUTPUT_DIR="${arg#*=}" ;;
        --mirror=*) MIRROR="${arg#*=}" ;;
        --with-pull) WITH_PULL=true ;;
        --rm-first) RM_FIRST=true ;;
        --use-mirror) USE_MIRROR=true ;;
    esac
done

# 如果使用镜像加速
if [ "$USE_MIRROR" = true ]; then
    MIRROR_CMD="-e DOWNLOAD_MIRROR=$MIRROR"
else
    MIRROR_CMD=""
fi

# 清理旧容器
if [ "$RM_FIRST" = true ]; then
    docker rm -f openwrt-builder || true
fi

# 拉取镜像
if [ "$WITH_PULL" = true ]; then
    docker pull $IMAGE
fi

# 运行 Docker 构建
docker run --name openwrt-builder -v $(pwd)/files:/builder/files -v $(pwd)/modules:/builder/modules -v $(pwd)/custom_modules:/builder/custom_modules -v $(pwd)/$OUTPUT_DIR:/builder/bin $MIRROR_CMD $IMAGE make image PROFILE=$PROFILE FILES=files PACKAGES="$(cat modules/*/packages custom_modules/*/packages | tr '\n' ' ')" DISABLED_SERVICES=""

echo "构建完成！固件位于 $OUTPUT_DIR"
