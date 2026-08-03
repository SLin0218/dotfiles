{ pkgs }:

pkgs.writeShellScriptBin "tproxy" ''
export PATH=$PATH:${pkgs.iproute2}/bin:${pkgs.nftables}/bin
set -euo pipefail

# 确保以 root 权限运行
if [[ "$EUID" -ne 0 ]]; then
    echo "错误：请使用 sudo 或以 root 用户运行此脚本。" >&2
    exit 1
fi
# 定义核心规则集函数
apply_rules() {
    ip route add local default dev lo table 100
    ip rule add fwmark 1 lookup 100

    echo "正在加载 nftables 代理规则..."
    nft -f - <<EOF
# 清理现有的所有规则集
flush ruleset

# 代理流量导向表
table ip singbox {
  set reserved_clusters {
    type ipv4_addr
    flags interval
    elements = {
      127.0.0.0/8,
      10.0.0.0/8,
      169.254.0.0/16,
      100.64.0.0/10,
      172.16.0.0/12,
      192.168.0.0/16,
      224.0.0.0/4,
      240.0.0.0/4
    }
  }

  chain prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname "virbr0" return
    udp dport 53 mark set 1 tproxy to 127.0.0.1:9898 accept
    ip daddr @reserved_clusters return
    meta l4proto {tcp, udp} mark set 1 tproxy to 127.0.0.1:9898 accept
  }

  chain output {
    type route hook output priority mangle; policy accept;
    meta skuid "mihomo" accept
    udp dport 53 mark set 1 accept
    ip daddr @reserved_clusters return
    meta l4proto {tcp, udp} mark set 1 accept
  }
}

EOF
    echo "nftables 规则加载成功！[状态: 已开启]"
}

# 清除代理规则函数（恢复默认）
flush_rules() {

    ip route del local default dev lo table 100
    ip rule del fwmark 1 lookup 100

    echo "正在清理代理规则并恢复默认..."
    # 清空所有规则，如果你是在 NixOS 下，后续可能需要执行 systemctl restart firewall 恢复系统默认
    nft flush ruleset
    echo "nftables 规则已全部清空！[状态: 已关闭]"
}

# 检查当前状态函数
check_status() {
    # 检查是否存在名为 'singbox' 的 table
    if nft list tables | grep -q "table ip singbox"; then
        echo "----------------------------------------"
        echo " 当前状态: 【 已开启 】"
        echo "----------------------------------------"
        echo "简要规则统计:"
        nft list table ip singbox
    else
        echo "----------------------------------------"
        echo " 当前状态: 【 已关闭 】"
        echo "----------------------------------------"
    fi
}

# 打印帮助信息
print_usage() {
    echo "使用方法: $0 [start|stop|toggle|status]"
    echo "  start  : 加载 nftables 代理规则"
    echo "  stop   : 清除所有 nftables 规则"
    echo "  toggle : 切换状态（如果开启则关闭，如果关闭则开启）"
    echo "  status : 查看当前规则运行状态"
}

# 主逻辑解析
COMMAND="''${1:-}"

case "$COMMAND" in
    start)
        apply_rules
        ;;
    stop)
        flush_rules
        ;;
    status)
        check_status
        ;;
    toggle)
        if nft list tables | grep -q "table ip singbox"; then
            echo "检测到代理规则已启用，正在关闭..."
            flush_rules
        else
            echo "检测到代理规则未启用，正在开启..."
            apply_rules
        fi
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
''
