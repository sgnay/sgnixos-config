# services/xray.nix — Xray 代理客户端，双模式 GeoIP 分流
{ config, lib, pkgs, secrets, ... }:
let
  common = import ../../common.nix;

  # 公共入站（xray / xray-home 共用）
  commonInbounds = [
    { port = 1080; listen = "127.0.0.1"; protocol = "http";
      sniffing = { enabled = true; destOverride = [ "http" "tls" ]; }; }
    { port = 1081; listen = "127.0.0.1"; protocol = "socks";
      settings.udp = true;
      sniffing = { enabled = true; destOverride = [ "http" "tls" "quic" ]; routeOnly = true; }; }
  ];

  # 公共路由规则：国内 IP 直连
  cnRules = [
    { type = "field"; ip = [ "geoip:cn" "geoip:private" ]; outboundTag = "direct"; }
  ];

  # 公共出站
  directOut = { tag = "direct"; protocol = "freedom"; };
  localOut  = { tag = "local-proxy"; protocol = "http";
    settings.servers = [{ address = common.network.proxyHost; port = common.network.proxyPort; }]; };

  # ---- xray-away (VLESS+REALITY) ----
  vlessOuts = secrets.xray-outbounds;  # 来自 secrets.nix

  mkAwayConfig = {
    inbounds = commonInbounds;
    outbounds = [ directOut localOut ] ++ vlessOuts;
    routing = {
      domainStrategy = "IPOnDemand";
      rules = cnRules ++ [
        { type = "field"; network = "tcp,udp"; outboundTag = "proxy"; }
      ];
    };
    log.loglevel = "warning";
  };

  # ---- xray-home (本地网关) ----
  mkHomeConfig = {
    inbounds = commonInbounds;
    outbounds = [ directOut localOut ];  # 只有直连和本地代理，无 VLESS
    routing = {
      domainStrategy = "IPOnDemand";
      rules = cnRules ++ [
        { type = "field"; network = "tcp,udp"; outboundTag = "local-proxy"; }
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
          pkgs.writeText "xray-away.json" (builtins.toJSON mkAwayConfig)
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
          pkgs.writeText "xray-home.json" (builtins.toJSON mkHomeConfig)
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${pkgs.v2ray-geoip}/share/v2ray";
      };
    };
  };
}
