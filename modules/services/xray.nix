# services/xray.nix — Xray 代理客户端，双模式 GeoIP 分流
{ config, lib, pkgs, ... }:
let
  common = import ../../common.nix;
  rawConfig = builtins.fromJSON (builtins.readFile ../../dotfiles/xray-config.json);

  # 公共出站 + 路由，仅默认出口不同
  directOut   = { tag = "direct"; protocol = "freedom"; };
  localOut    = { tag = "local-proxy"; protocol = "http";
    settings.servers = [{ address = common.network.proxyHost; port = common.network.proxyPort; }]; };
  vlessOuts   = rawConfig.outbounds;  # VLESS+REALITY 出口列表

  cnRules = [
    { type = "field"; ip = [ "geoip:cn" "geoip:private" ]; outboundTag = "direct"; }
  ];

  mkConfig = defaultTag: {
    inbounds = [
      { port = 1080; listen = "127.0.0.1"; protocol = "http";
        sniffing = { enabled = true; destOverride = [ "http" "tls" ]; }; }
      { port = 1081; listen = "127.0.0.1"; protocol = "socks";
        settings.udp = true;
        sniffing = { enabled = true; destOverride = [ "http" "tls" "quic" ]; routeOnly = true; }; }
    ];
    outbounds = [ directOut localOut ] ++ vlessOuts;
    routing = {
      domainStrategy = "IPOnDemand";
      rules = cnRules ++ [
        { type = "field"; network = "tcp,udp"; outboundTag = defaultTag; }
      ];
    };
    log.loglevel = "warning";
  };
in
{
  environment.systemPackages = with pkgs; [
    xray
    v2ray-geoip
    clash-verge-rev      # Clash GUI 代理管理客户端
  ];

  systemd.services = {
    xray = {
      description = "Xray Proxy (Away: VLESS+REALITY)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-away.json" (builtins.toJSON (mkConfig "proxy"))
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${pkgs.v2ray-geoip}/share/v2ray";
      };
    };

    xray-home = {
      description = "Xray Proxy (Home: Local)";
      after = [ "network.target" ];
      wantedBy = lib.mkForce [];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-home.json" (builtins.toJSON (mkConfig "local-proxy"))
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${pkgs.v2ray-geoip}/share/v2ray";
      };
    };
  };
}
