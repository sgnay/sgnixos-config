if status is-interactive
    # Commands to run in interactive sessions can go here
end

set PATH $HOME/bin $HOME/.cargo/bin $HOME/.npm-global/bin/ $HOME/.local/bin/ $HOME/.bun/bin $PATH
set fish_greeting
starship init fish | source

# Proxy aliases (restricted network access via mainland China)
# Note: use -g (--global) so variables propagate outside the function scope
# Xray 本地代理 — 统一入口：127.0.0.1:1080 (HTTP) / 127.0.0.1:1081 (SOCKS5)
# 模式切换：proxy-public (VLESS公网) / proxy-home (家庭网关) / proxy-clash (Clash转接) / proxy-on (全直连兼容保活) / proxy-off (关环境变量)
alias proxy-public='sudo systemctl start xray-public; set -gx HTTP_PROXY http://127.0.0.1:1080; set -gx HTTPS_PROXY http://127.0.0.1:1080; set -gx ALL_PROXY socks5://127.0.0.1:1081; set -gx NO_PROXY localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16; set -gx http_proxy $HTTP_PROXY; set -gx https_proxy $HTTPS_PROXY; set -gx all_proxy $ALL_PROXY; set -gx no_proxy $NO_PROXY'
alias proxy-home='sudo systemctl start xray-home; set -gx HTTP_PROXY http://127.0.0.1:1080; set -gx HTTPS_PROXY http://127.0.0.1:1080; set -gx ALL_PROXY socks5://127.0.0.1:1081; set -gx NO_PROXY localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16; set -gx http_proxy $HTTP_PROXY; set -gx https_proxy $HTTPS_PROXY; set -gx all_proxy $ALL_PROXY; set -gx no_proxy $NO_PROXY'
alias proxy-clash='sudo systemctl start xray-clash; set -gx HTTP_PROXY http://127.0.0.1:1080; set -gx HTTPS_PROXY http://127.0.0.1:1080; set -gx ALL_PROXY socks5://127.0.0.1:1081; set -gx NO_PROXY localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16; set -gx http_proxy $HTTP_PROXY; set -gx https_proxy $HTTPS_PROXY; set -gx all_proxy $ALL_PROXY; set -gx no_proxy $NO_PROXY'
alias proxy-on='sudo systemctl start xray-none; set -gx HTTP_PROXY http://127.0.0.1:1080; set -gx HTTPS_PROXY http://127.0.0.1:1080; set -gx ALL_PROXY socks5://127.0.0.1:1081; set -gx NO_PROXY localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16; set -gx http_proxy $HTTP_PROXY; set -gx https_proxy $HTTPS_PROXY; set -gx all_proxy $ALL_PROXY; set -gx no_proxy $NO_PROXY'
alias proxy-off='set -eg HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY; set -eg http_proxy https_proxy all_proxy no_proxy'
# Quick rebuild (auto-update secrets-file input before building)
alias rebuild='sudo nixos-rebuild switch --flake /etc/nixos#sgnixos'

# Git aliases
alias gits='git status'
alias gitl='git log'
# Alternative to the 'cd'
eval "$(zoxide init fish)"

# Added by Antigravity CLI installer
set -gx PATH "/home/sgnay/.local/bin" $PATH

# ---- 命令拼写纠错：pay-respects (nix profile: nixpkgs#pay-respects) ----
# 命令报 "not found" 后，先给出修正建议，按 y 才执行，回车/N 跳过。
# 按 F 可打开 pay-respects 自己的多候选菜单。
if type -q pay-respects
    pay-respects fish --alias | source

    # 命中这些首词、或带强制/管道执行特征时，标记为危险，提示里会加警告
    function __pr_dangerous
        set -l cmd (string join ' ' -- $argv)
        set -l head (string split -m1 ' ' -- (string trim -- $cmd))[1]
        set -l risky rm rmdir dd shred mkfs fdisk parted mount umount chmod chown chgrp \
            mv truncate kill killall pkill reboot shutdown poweroff halt sudo doas run0 su \
            systemctl nixos-rebuild nix nix-env pacman apt dnf zypper userdel useradd \
            passwd curl wget ssh scp rsync docker podman kubectl terraform
        contains -- $head $risky; and return 0
        string match -qr -- '\|\s*(ba|z|da)?sh|>\s*/dev/|:\(\)\s*\{|--force|--hard|clean\s+-[a-zA-Z]*f' "$cmd"; and return 0
        return 1
    end

    function fish_command_not_found --on-event fish_command_not_found
        set -l typed (string join ' ' -- $argv)
        # echo 模式：取首个候选，不弹交互菜单
        set -l raw (_PR_SHELL=fish _PR_MODE=echo _PR_LAST_COMMAND="$typed" pay-respects 2>/dev/null)
        set -l fix (string split -m1 '<PR_BR>' -- $raw)[1]
        set -l head (string split -m1 ' ' -- $fix)[1]

        # 没建议 / 目标不是真实可执行文件 → 交给 pay-respects 原生菜单
        if test -z "$fix"; or not command -q -- $head
            __pr_base cnf "$typed"
            return
        end

        # 只提示，不执行
        if __pr_dangerous $fix
            set_color yellow
            printf '⚠ 建议(危险命令): %s\n' "$fix"
        else
            set_color brblack
            printf '建议: %s\n' "$fix"
        end
        set_color brblack
        printf '执行? [y/N] '
        set_color normal

        set -l ans
        read -l -n 1 -P '' ans < /dev/tty
        or return
        printf '\n'

        if not string match -qi 'y' -- "$ans"
            set_color brblack
            printf '已跳过(按 F 可看全部候选)\n'
            set_color normal
            return
        end

        builtin history append -- "$fix"
        eval $fix
    end
end
