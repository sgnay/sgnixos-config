# modules/services/network-storage.nix — 网络存储服务
#   kdeconnect: KDE Connect 手机与电脑互联
#   nfs-utils:  NFS 客户端工具 + 服务端
#   samba:      SMB/CIFS 服务端 + 客户端挂载（cifs-utils）
{ pkgs, lib, ... }:
let
  common = import ../../common.nix;
  userName = common.username;
in
{
  # === 系统包: KDE Connect + NFS + Samba ===
  environment.systemPackages = with pkgs; [
    kdePackages.kdeconnect-kde # 手机-电脑互联
    nfs-utils # NFS 客户端/服务端工具
    samba # SMB/CIFS 服务端
    cifs-utils # mount -t cifs 支持
  ];

  # KDE Connect 需要防火墙放行
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  # === NFS 服务端 ===
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    # 在此添加 NFS 共享目录，例如：
    # /export    *(rw,fsid=0,no_subtree_check)
    # /export/shared  *(rw,nohide,insecure,no_subtree_check)
  '';

  fileSystems."/home/data/_mountpoint_nfs" = {
    device = "172.20.26.100:/home/sgdata";
    fsType = "nfs";
    options = [
      "nolock" # 禁用文件锁（提高 NFS 性能）
      "nofail" # 挂载失败不阻塞启动
      "noauto" # 开机不自动挂载 .mount 单元
      "_netdev" # 网络文件系统，等待网络就绪
      "soft" # 软挂载（超时后返回错误而非挂起）
      "timeo=30" # 超时时间 3 秒（默认 0.7 秒的 30 倍）
      "retrans=3" # 重试次数
    ];
  };

  # 显式定义 automount 单元，并将 wantedBy 设为空 []
  # 避免 systemd-fstab-generator 自动启用，同时保证 unit 结构完整不被 systemd mark/mask
  systemd.automounts = [
    {
      where = "/home/data/_mountpoint_nfs";
      wantedBy = [ ]; # 不在任何开机 target 中自动启用
      automountConfig = {
        TimeoutIdleSec = "600s";
        MountTimeoutSec = "5s";
      };
    }
  ];

  # NFS 端口探针服务：检测 2049 端口，可达则启动 automount，不可达则停止 automount
  systemd.services.nfs-automount-watcher = {
    description = "NFS Automount Health Check & Dynamic Toggle";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nfs-watcher" ''
        NFS_HOST="172.20.26.100"
        NFS_PORT=2049
        AUTOMOUNT_UNIT="home-data-_mountpoint_nfs.automount"

        if ${pkgs.netcat-openbsd}/bin/nc -z -w 2 "$NFS_HOST" "$NFS_PORT" >/dev/null 2>&1; then
          if ! ${pkgs.systemd}/bin/systemctl is-active --quiet "$AUTOMOUNT_UNIT"; then
            echo "NFS server $NFS_HOST:$NFS_PORT is reachable, starting $AUTOMOUNT_UNIT..."
            ${pkgs.systemd}/bin/systemctl start "$AUTOMOUNT_UNIT"
          fi
        else
          if ${pkgs.systemd}/bin/systemctl is-active --quiet "$AUTOMOUNT_UNIT"; then
            echo "NFS server $NFS_HOST:$NFS_PORT is unreachable, stopping $AUTOMOUNT_UNIT..."
            ${pkgs.systemd}/bin/systemctl stop "$AUTOMOUNT_UNIT"
          fi
        fi
      '';
    };
  };

  # 定时器：每 15 秒运行一次探针服务（替代常驻死循环进程，极其节省资源）
  systemd.timers.nfs-automount-watcher = {
    description = "Timer for NFS Automount Health Check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };

  # === Samba 服务端 ===

  services.samba = {
    enable = true;
    package = pkgs.samba; # 显式指定包
    openFirewall = true; # 自动开放 137-139, 445 端口
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

  # 禁用 samba.target, samba-smbd, samba-nmbd 的开机自启动
  systemd.targets.samba.wantedBy = lib.mkForce [ ];
  systemd.services.samba-smbd.wantedBy = lib.mkForce [ ];
  systemd.services.samba-nmbd.wantedBy = lib.mkForce [ ];

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
    dataDir = "/home/${userName}"; # 配置文件目录
    configDir = "/home/${userName}/.config/syncthing";
    overrideFolders = false; # 保留用户已有的文件夹配置
    overrideDevices = false; # 保留用户已有的设备配置
    guiAddress = "127.0.0.1:8384";
  };
}
