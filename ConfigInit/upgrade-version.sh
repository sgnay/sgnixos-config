#!/usr/bin/env bash
set -euo pipefail

# NixOS 版本升级脚本
# 用途：统一升级 NixOS 和 Home Manager 版本号

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FILE="$SCRIPT_DIR/common.nix"
FLAKE_FILE="$SCRIPT_DIR/flake.nix"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印信息
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查文件是否存在
check_file() {
    if [[ ! -f "$1" ]]; then
        error "文件不存在: $1"
        exit 1
    fi
}

# 检查 git 工作区是否干净（仅在有 .git 目录时）
check_git_clean() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if ! git diff --quiet || ! git diff --cached --quiet; then
            warn "Git 工作区有未提交的变更"
            echo -e "  ${YELLOW}建议先提交或暂存当前变更再继续${NC}"
            echo -e "  ${YELLOW}继续操作可能造成混淆${NC}"
            echo ""
            read -rp "是否继续？[y/N] " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                info "已取消"
                exit 0
            fi
        fi
    fi
}

# 从 common.nix 读取版本号
read_version() {
    check_file "$COMMON_FILE"
    VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' "$COMMON_FILE" || true)
    
    if [[ -z "$VERSION" ]]; then
        error "无法从 $COMMON_FILE 读取版本号"
        exit 1
    fi
    
    info "当前版本号: $VERSION"
}

# 备份文件
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    info "已备份: $backup"
}

# 更新 flake.nix 中的 inputs URL
update_flake_inputs() {
    check_file "$FLAKE_FILE"
    
    info "更新 $FLAKE_FILE 中的 inputs..."
    
    # 备份文件
    backup_file "$COMMON_FILE"
    backup_file "$FLAKE_FILE"
    
    # 使用 sed 更新版本号
    # 匹配 nixos-XX.XX 和 release-XX.XX
    sed -i \
        -e "s|nixos-[0-9]\+\.[0-9]\+|nixos-${VERSION}|g" \
        -e "s|release-[0-9]\+\.[0-9]\+|release-${VERSION}|g" \
        "$FLAKE_FILE"
    
    info "已更新 inputs URL"
}

# 更新 flake.lock
update_flake_lock() {
    info "更新 flake.lock..."
    cd "$SCRIPT_DIR"
    
    if nix flake update; then
        info "flake.lock 更新成功"
    else
        error "flake.lock 更新失败"
        warn "请手动执行: nix flake update"
        exit 1
    fi
}

# 显示变更
show_changes() {
    info "变更摘要:"
    echo "  - 版本号:                      $VERSION"
    echo "  - 来源:                        $COMMON_FILE"
    echo "  - 已更新:                      $FLAKE_FILE"
    echo "  - 备份:                        $COMMON_FILE.backup.*"
    echo "  - 备份:                        $FLAKE_FILE.backup.*"
    echo ""
    info "下一步:"
    echo "  1. 检查变更: git diff $FLAKE_FILE $COMMON_FILE"
    echo "  2. 测试配置: sudo nixos-rebuild test"
    echo "  3. 应用配置: sudo nixos-rebuild switch"
}

# 主函数
main() {
    info "NixOS 版本升级脚本"
    echo ""
    
    check_git_clean
    read_version
    update_flake_inputs
    update_flake_lock
    show_changes
    
    info "升级完成！"
}

# 运行主函数
main "$@"
