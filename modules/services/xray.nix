# services/xray.nix — Xray 代理客户端，双模式 GeoIP 分流
{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ../../common.nix;

  # 公共入站（xray / xray-home 共用）
  commonInbounds = [
    {
      port = 1080;
      listen = "0.0.0.0";
      protocol = "http";
      sniffing = {
        enabled = true;
        destOverride = ["http" "tls" "quic"];
      };
    }
    {
      port = 1081;
      listen = "127.0.0.1";
      protocol = "socks";
      settings = {
        auth = "noauth";
        udp = true;
        userLevel = 8;
      };
      sniffing = {
        enabled = true;
        destOverride = ["http" "tls" "quic"];
        routeOnly = false;
      };
      tag = "socks";
    }
  ];

  # 公共出站
  directOut = {
    tag = "direct";
    protocol = "freedom";
    streamSettings = {
      network = "tcp";
      sockopt = {domainStrategy = "UseIP";};
    };
  };
  localOut = {
    tag = "local-proxy";
    protocol = "http";
    settings.servers = [
      {
        address = common.network.proxyHost;
        port = common.network.proxyPort;
      }
    ];
  };
  blockOut = {
    tag = "block";
    protocol = "blackhole";
    settings.response.type = "http";
  };

  # DNS 配置
  awayDns = {
    hosts = {
      "domain:googleapis.cn" = "googleapis.com";
      "dns.alidns.com" = ["223.5.5.5" "223.6.6.6" "2400:3200::1" "2400:3200:baba::1"];
      "one.one.one.one" = ["1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"];
      "dns.cloudflare.com" = ["104.16.132.229" "104.16.133.229" "2606:4700::6810:84e5" "2606:4700::6810:85e5"];
      "cloudflare-dns.com" = ["104.16.248.249" "104.16.249.249" "2606:4700::6810:f8f9" "2606:4700::6810:f9f9"];
      "dot.pub" = ["1.12.12.12" "120.53.53.53"];
      "dns.google" = ["8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
      "dns.quad9.net" = ["9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9"];
      "common.dot.dns.yandex.net" = ["77.88.8.8" "77.88.8.1" "2a02:6b8::feed:0ff" "2a02:6b8:0:1::feed:0ff"];
    };
    servers = [
      "1.1.1.1"
      {
        address = "1.1.1.1";
        domains = ["geosite:google"];
      }
      {
        address = "223.5.5.5";
        domains = ["geosite:private" "domain:alidns.com" "domain:doh.pub" "domain:dot.pub" "domain:360.cn" "domain:onedns.net"];
        skipFallback = true;
        tag = "domestic-dns0";
      }
      {
        address = "223.5.5.5";
        domains = ["geosite:cn"];
        expectIPs = ["geoip:cn"];
        skipFallback = true;
        tag = "domestic-dns0_cn_expect";
      }
    ];
    tag = "dns-module";
  };

  # 国内 DNS 服务器 IP 列表（用于路由直连规则）
  cnDnsIps = [
    "223.5.5.5"
    "223.6.6.6"
    "2400:3200::1"
    "2400:3200:baba::1"
    "119.29.29.29"
    "1.12.12.12"
    "120.53.53.53"
    "2402:4e00::"
    "2402:4e00:1::"
    "180.76.76.76"
    "2400:da00::6666"
    "114.114.114.114"
    "114.114.115.115"
    "114.114.114.119"
    "114.114.115.119"
    "114.114.114.110"
    "114.114.115.110"
    "180.184.1.1"
    "180.184.2.2"
    "101.226.4.6"
    "218.30.118.6"
    "123.125.81.6"
    "140.207.198.6"
    "1.2.4.8"
    "210.2.4.8"
    "52.80.66.66"
    "117.50.22.22"
    "2400:7fc0:849e:200::4"
    "2404:c2c0:85d8:901::4"
    "117.50.10.10"
    "52.80.52.52"
    "2400:7fc0:849e:200::8"
    "2404:c2c0:85d8:901::8"
    "117.50.60.30"
    "52.80.60.30"
  ];

  # 路由规则
  awayRules = [
    # 封锁 UDP 443（QUIC 干扰）
    {
      type = "field";
      network = "udp";
      port = "443";
      outboundTag = "block";
    }
    # Google 走代理
    {
      type = "field";
      domain = ["geosite:google"];
      outboundTag = "proxy-xhttp";
    }
    # 私有地址直连
    {
      type = "field";
      ip = ["ext:geoip.dat:private"];
      outboundTag = "direct";
    }
    {
      type = "field";
      domain = ["geosite:private"];
      outboundTag = "direct";
    }
    # 国内 DNS 服务器直连
    {
      type = "field";
      ip = cnDnsIps;
      outboundTag = "direct";
    }
    {
      type = "field";
      domain = ["domain:alidns.com" "domain:doh.pub" "domain:dot.pub" "domain:360.cn" "domain:onedns.net"];
      outboundTag = "direct";
    }
    # 国内 IP/域名直连
    {
      type = "field";
      ip = ["ext:geoip.dat:cn"];
      outboundTag = "direct";
    }
    {
      type = "field";
      domain = ["geosite:cn"];
      outboundTag = "direct";
    }
    # DNS 入口标签路由
    {
      type = "field";
      inboundTag = ["domestic-dns0" "domestic-dns0_cn_expect"];
      outboundTag = "direct";
    }
    {
      type = "field";
      inboundTag = ["dns-module"];
      outboundTag = "proxy-xhttp";
    }
    # 兜底：未匹配以上规则的流量全部走代理
    {
      type = "field";
      network = "tcp,udp";
      outboundTag = "proxy-xhttp";
    }
  ];

  # ---- xray-home (本地网关) ----
  mkHomeConfig = {
    inbounds = commonInbounds;
    outbounds = [directOut localOut blockOut]; # 只有直连和本地代理，无 VLESS
    routing = {
      domainStrategy = "IPOnDemand";
      rules = [
        {
          type = "field";
          ip = ["geoip:cn" "geoip:private"];
          outboundTag = "direct";
        }
        {
          type = "field";
          network = "tcp,udp";
          outboundTag = "local-proxy";
        }
      ];
    };
    log.loglevel = "warning";
  };

  # 合并 geoip.dat + geosite.dat 到同一目录供 Xray 使用
  xrayAssets = pkgs.symlinkJoin {
    name = "xray-assets";
    paths = [
      "${pkgs.v2ray-geoip}/share/v2ray"
      "${pkgs.v2ray-domain-list-community}/share/v2ray"
    ];
  };
in {
  sops.secrets.xray-outbounds = {
    sopsFile = ../../secrets.yaml;
  };

  sops.templates."xray-away.json".content = ''
    {
      "inbounds": ${builtins.toJSON commonInbounds},
      "outbounds": [
        ${builtins.toJSON directOut},
        ${builtins.toJSON localOut},
        ${builtins.toJSON blockOut},
        ${config.sops.placeholder."xray-outbounds"}
      ],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": ${builtins.toJSON awayRules}
      },
      "dns": ${builtins.toJSON awayDns},
      "log": {
        "loglevel": "warning"
      }
    }
  '';

  systemd.services = {
    xray = {
      description = "Xray Proxy (Away: VLESS+REALITY)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      conflicts = ["xray-home.service"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${config.sops.templates."xray-away.json".path}";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };

    xray-home = {
      description = "Xray Proxy (Home: Local)";
      after = ["network.target"];
      wantedBy = lib.mkForce [];
      conflicts = ["xray.service"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-home.json" (builtins.toJSON mkHomeConfig)
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };
  };
}
