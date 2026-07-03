# modules/services/network-storage.nix — 网络存储服务
#   kdeconnect: KDE Connect 手机与电脑互联
#   nfs-utils:  NFS 客户端工具 + 服务端
#   samba:      SMB/CIFS 服务端 + 客户端挂载（cifs-utils）
{ config, pkgs, lib, secrets, ... }:
let
  userName = secrets.username;
in
{
  # === 系统包: KDE Connect + NFS + Samba ===
  environment.systemPackages = with pkgs; [
    kdePackages.kdeconnect-kde        # 手机-电脑互联
    nfs-utils                         # NFS 客户端/服务端工具
    samba                             # SMB/CIFS 服务端
    cifs-utils                        # mount -t cifs 支持
  ];

  # KDE Connect 需要防火墙放行
  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };

  # === NFS 服务端 ===
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    # 在此添加 NFS 共享目录，例如：
    # /export    *(rw,fsid=0,no_subtree_check)
    # /export/shared  *(rw,nohide,insecure,no_subtree_check)
  '';

  # === NFS 客户端按需挂载（NAS 共享） ===
  # NAS: 172.20.26.100 (sgnas)，通过 x-systemd.automount 实现访问时自动挂载
  fileSystems."/mnt/sgdata" = {
    device = "172.20.26.100:/home/sgdata";
    fsType = "nfs";
    options = [
      "nolock"                      # 禁用文件锁（提高 NFS 性能）
      "nofail"                      # 挂载失败不阻塞启动
      "noauto"                      # 开机不自动挂载
      "x-systemd.automount"         # 按需挂载：访问目录时自动挂载
      "x-systemd.idle-timeout=600"  # 无活动 10 分钟后自动卸载
      "_netdev"                     # 网络文件系统，等待网络就绪
      "soft"                        # 软挂载（超时后返回错误而非挂起）
      "timeo=30"                    # 超时时间 3 秒（默认 0.7 秒的 30 倍）
      "retrans=3"                   # 重试次数
    ];
  };

  # === Samba 服务端 ===

  services.samba = {
    enable = true;
    package = pkgs.samba;             # 显式指定包
    openFirewall = true;              # 自动开放 137-139, 445 端口
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "sgnixos";
        "netbios name" = "sgnixos";
        "security" = "user";
        # 使用 smbpasswd 设置用户密码:
        #   sudo smbpasswd -a ${userName}
        "map to guest" = "Bad User";
        "guest account" = "nobody";
      };
      # 默认共享目录示例（可根据需要调整）
      # homes = {
      #   comment = "Home Directories";
      #   browseable = "no";
      #   read only = "no";
      #   "valid users" = "%S";
      # };
      # public = {
      #   path = "/srv/samba/public";
      #   comment = "Public Share";
      #   public = "yes";
      #   "writable" = "yes";
      #   "guest ok" = "yes";
      #   "create mask" = "0644";
      #   "directory mask" = "0755";
      # };
    };
  };

  # 启用 Samba 的 NetBIOS 名称解析服务
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # 将用户加入 sambashare 组（可选）
  users.users.${userName}.extraGroups = [ "sambashare" ];

  # === Syncthing 文件同步 ===
  services.syncthing = {
    enable = true;
    user = userName;
    dataDir = "/home/${userName}";    # 配置文件目录
    configDir = "/home/${userName}/.config/syncthing";
    overrideFolders = false;           # 保留用户已有的文件夹配置
    overrideDevices = false;           # 保留用户已有的设备配置
    guiAddress = "127.0.0.1:8384";
  };
}
