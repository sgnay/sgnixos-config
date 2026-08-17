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
# Alternative to the 'cd'
eval "$(zoxide init fish)"

# Added by Antigravity CLI installer
set -gx PATH "/home/sgnay/.local/bin" $PATH
