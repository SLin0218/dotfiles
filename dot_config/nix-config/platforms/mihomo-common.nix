{ ... }:
let
  jmssub = import ./jmssub.nix;
in
{
  mkSettings = {

    proxy-providers = {
      JMS = {
        url = "https://jmssub.net/members/getsub.php?service=${jmssub.service}&id=${jmssub.id}";
        type = "http";
        proxy = "DIRECT";
        # 2 小时更新一次
        interval = 7200;
        health-check = {
          enable = true;
          url = "https://www.gstatic.com/generate_204";
          interval = 300;
        };
        override = {
          proxy-name = [
            {
              pattern = ".*c10s(\\d{0,3}).*";
              target = "jms-$1";
            }
          ];
        };
      };
    };

    tproxy-port = 9898;
    tun = {
      enable = false;
      stack = "mixed";
      dns-hijack = [ "any:53" ];
      auto-route = true;
      auto-redirect = true;
      auto-detect-interface = true;
    };
    mixed-port = 7890;
    bind-address = "*";
    mode = "rule";
    log-level = "info";
    geox-url = {
      geoip = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat";
      geosite = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat";
      mmdb = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb";
    };
    geo-auto-update = true;
    geo-update-interval = 24;

    external-controller = "127.0.0.1:9090";
    external-ui = "ui";
    external-ui-url = "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip";

    ipv6 = false;

    # 性能优化
    unified-delay = true;
    tcp-concurrent = true;
    profile = {
      store-selected = true;
      store-fake-ip = true;
    };

    proxies = [ ];

    dns = {
      cache-algorithm = "arc";
      enable = true;
      listen = "127.0.0.1:1053";
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      fake-ip-filter = [
        "*.lan"
        "*.localdomain"
        "*.example"
        "*.invalid"
        "*.localhost"
        "*.test"
        "*.local"
        "+.container"
        "*.home.arpa"
        "+.msftconnecttest.com"
        "+.msftncsi.com"
      ];

      default-nameserver = [
        "223.5.5.5"
        "114.114.114.114"
      ];
      nameserver = [
        "https://dns.alidns.com/dns-query"
        "https://doh.pub/dns-query"
      ];
      fallback = [
        "https://1.1.1.1/dns-query"
        "https://8.8.8.8/dns-query"
        "tls://dns.google"
      ];
      fallback-filter = {
        geoip = true;
        geoip-code = "CN";
        geosite = [ "gfw" ];
        ipcidr = [ "240.0.0.0/4" ];
      };
      nameserver-policy = {
        "jmssub.net" = [
          "https://dns.alidns.com/dns-query"
          "https://doh.pub/dns-query"
        ];
        "geosite:cn" = [
          "https://dns.alidns.com/dns-query"
          "https://doh.pub/dns-query"
        ];
        "geosite:gfw,geolocation-!cn" = [
          "https://1.1.1.1/dns-query"
          "https://8.8.8.8/dns-query"
        ];
        # 本地容器域名解析
        "+.container" = [
          "127.0.0.1:2053"
        ];
      };
    };

    sniffer = {
      enable = true;
      sniff = {
        HTTP = {
          ports = [
            "80"
            "8080-8880"
          ];
          override-destination = true;
        };
        TLS = {
          ports = [
            443
            8443
          ];
        };
        QUIC = {
          ports = [
            443
            8443
          ];
        };
      };
      skip-domain = [
        "Mijia Cloud"
        "dlg.io.mi.com"
      ];
    };

    rules = [
      "DOMAIN-SUFFIX,localhost,DIRECT"
      "DOMAIN-SUFFIX,container,DIRECT"
      "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve"
      "IP-CIDR,172.16.0.0/12,DIRECT,no-resolve"
      "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve"
      "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve"

      "GEOIP,CN,DIRECT"
      "GEOSITE,category-ads-all,REJECT"

      "GEOSITE,CN,DIRECT"
      "GEOSITE,geolocation-!cn,PROXY"
      "MATCH,PROXY"
    ];

    proxy-groups = [
      {
        name = "AUTO";
        type = "url-test";
        use = [ "JMS" ];
        url = "https://www.gstatic.com/generate_204";
        interval = 300;
        tolerance = 50;
      }
      {
        name = "PROXY";
        type = "select";
        proxies = [ "AUTO" ];
        use = [ "JMS" ];
      }
    ];
  };
}
