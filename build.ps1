# 构建脚本（Windows PowerShell）

# 加载 .env 文件
if (Test-Path .env) {
    Get-Content .env | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $name, $value = $_ -split '=', 2
        Set-Item -Path "env:$name" -Value $value
    }
}

# 默认参数
$IMAGE = if ($env:IMAGE) { $env:IMAGE } else { "openwrt/imagebuilder:rockchip-armv8-24.10.1" }
$PROFILE = if ($env:PROFILE) { $env:PROFILE } else { "friendlyarm_nanopi-r2s" }
$OUTPUT_DIR = if ($env:OUTPUT_DIR) { $env:OUTPUT_DIR } else { "./bin" }
$MIRROR = if ($env:MIRROR) { $env:MIRROR } else { "downloads.openwrt.org" }
$WITH_PULL = if ($env:WITH_PULL) { $env:WITH_PULL } else { $true }
$RM_FIRST = if ($env:RM_FIRST) { $env:RM_FIRST } else { $true }
$USE_MIRROR = if ($env:USE_MIRROR) { $env:USE_MIRROR } else { $false }

# 帮助信息
if ($args -contains "--help" -or $args -contains "-Help") {
    Write-Output "Usage: .\build.ps1 [options]"
    Write-Output "Options:"
    Write-Output "  -Image IMAGE         Docker 镜像 (default: $IMAGE)"
    Write-Output "  -Profile PROFILE     设备 profile (default: $PROFILE)"
    Write-Output "  -Output DIR          输出目录 (default: $OUTPUT_DIR)"
    Write-Output "  -Mirror MIRROR       下载镜像 (default: $MIRROR)"
    Write-Output "  -WithPull            拉取最新镜像"
    Write-Output "  -RmFirst             先移除旧容器"
    Write-Output "  -UseMirror           使用镜像加速"
    exit 0
}

# 解析参数
foreach ($arg in $args) {
    if ($arg -match "^-Image=(.*)$") { $IMAGE = $Matches[1] }
    if ($arg -match "^-Profile=(.*)$") { $PROFILE = $Matches[1] }
    if ($arg -match "^-Output=(.*)$") { $OUTPUT_DIR = $Matches[1] }
    if ($arg -match "^-Mirror=(.*)$") { $MIRROR = $Matches[1] }
    if ($arg -eq "-WithPull") { $WITH_PULL = $true }
    if ($arg -eq "-RmFirst") { $RM_FIRST = $true }
    if ($arg -eq "-UseMirror") { $USE_MIRROR = $true }
}

# 如果使用镜像加速
if ($USE_MIRROR) {
    $MIRROR_CMD = "-e DOWNLOAD_MIRROR=$MIRROR"
} else {
    $MIRROR_CMD = ""
}

# 清理旧容器
if ($RM_FIRST) {
    docker rm -f openwrt-builder
}

# 拉取镜像
if ($WITH_PULL) {
    docker pull $IMAGE
}

# 运行 Docker 构建
$PACKAGES = (Get-Content modules/*/packages, custom_modules/*/packages) -join ' '
docker run --name openwrt-builder -v "$PWD/files:/builder/files" -v "$PWD/modules:/builder/modules" -v "$PWD/custom_modules:/builder/custom_modules" -v "$PWD/$OUTPUT_DIR:/builder/bin" $MIRROR_CMD $IMAGE make image PROFILE=$PROFILE FILES=files PACKAGES="$PACKAGES" DISABLED_SERVICES=""

Write-Output "构建完成！固件位于 $OUTPUT_DIR"
