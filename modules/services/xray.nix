# services/xray.nix — Xray 代理客户端，支持多模式切换 (public / home / clash / none)
{
  config,
  lib,
  pkgs,
  ...
}: let
  # 公共入站（统一使用 1080 HTTP 和 1081 SOCKS）
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

  # 公共基础出站
  directOut = {
    tag = "direct";
    protocol = "freedom";
    streamSettings = {
      network = "tcp";
      sockopt = {domainStrategy = "UseIP";};
    };
  };
  blockOut = {
    tag = "block";
    protocol = "blackhole";
    settings.response.type = "http";
  };

  # 模式专属上游出站
  homeOut = {
    tag = "home-proxy";
    protocol = "http";
    settings.servers = [
      {
        address = "172.20.26.100";
        port = 1080;
      }
    ];
  };
  clashOut = {
    tag = "clash-proxy";
    protocol = "http";
    settings.servers = [
      {
        address = "127.0.0.1";
        port = 7890;
      }
    ];
  };

  # DNS 配置
  commonDns = {
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

  # 国内 DNS 服务器 IP 列表
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

  # 通用路由规则生成器
  mkRules = targetTag: [
    # 封锁 UDP 443（QUIC 干扰）
    {
      type = "field";
      network = "udp";
      port = "443";
      outboundTag = "block";
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
      outboundTag = targetTag;
    }
    # 兜底：未匹配以上规则的流量转至指定目标出站
    {
      type = "field";
      network = "tcp,udp";
      outboundTag = targetTag;
    }
  ];

  # 非敏感配置生成器 (home / clash / none)
  mkConfig = {
    outbounds,
    targetTag,
  }: {
    inbounds = commonInbounds;
    inherit outbounds;
    routing = {
      domainStrategy = "AsIs";
      rules = mkRules targetTag;
    };
    dns = commonDns;
    log.loglevel = "warning";
  };

  # 4 个互斥服务名称列表
  allServices = [
    "xray-public.service"
    "xray-home.service"
    "xray-clash.service"
    "xray-none.service"
  ];

  # 合并 geoip.dat + geosite.dat
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

  # SOPS 动态渲染加密的 Public 配置
  sops.templates."xray-public.json".content = ''
    {
      "inbounds": ${builtins.toJSON commonInbounds},
      "outbounds": [
        ${builtins.toJSON directOut},
        ${builtins.toJSON blockOut},
        ${config.sops.placeholder."xray-outbounds"}
      ],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": ${builtins.toJSON (mkRules "proxy-xhttp")}
      },
      "dns": ${builtins.toJSON commonDns},
      "log": {
        "loglevel": "warning"
      }
    }
  '';

  systemd.services = {
    xray-public = {
      description = "Xray Proxy (Public: VLESS+REALITY)";
      after = [
        "network.target"
        "sops-nix.service"
      ];
      wants = ["sops-nix.service"];
      wantedBy = ["multi-user.target"];
      conflicts = builtins.filter (s: s != "xray-public.service") allServices;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${config.sops.templates."xray-public.json".path}";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };

    xray-home = {
      description = "Xray Proxy (Home: Upstream 172.20.26.100:1080)";
      after = ["network.target"];
      wantedBy = lib.mkForce [];
      conflicts = builtins.filter (s: s != "xray-home.service") allServices;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-home.json" (builtins.toJSON (mkConfig {
            outbounds = [directOut blockOut homeOut];
            targetTag = "home-proxy";
          }))
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };

    xray-clash = {
      description = "Xray Proxy (Clash: Upstream 127.0.0.1:7890)";
      after = ["network.target"];
      wantedBy = lib.mkForce [];
      conflicts = builtins.filter (s: s != "xray-clash.service") allServices;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-clash.json" (builtins.toJSON (mkConfig {
            outbounds = [directOut blockOut clashOut];
            targetTag = "clash-proxy";
          }))
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };

    xray-none = {
      description = "Xray Proxy (None: 100% Direct Fallback)";
      after = ["network.target"];
      wantedBy = lib.mkForce [];
      conflicts = builtins.filter (s: s != "xray-none.service") allServices;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.xray}/bin/xray run -config ${
          pkgs.writeText "xray-none.json" (builtins.toJSON (mkConfig {
            outbounds = [directOut blockOut];
            targetTag = "direct";
          }))
        }";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XRAY_LOCATION_ASSET=${xrayAssets}";
      };
    };
  };
}
