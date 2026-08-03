{ config, pkgs, lib, ... }:

let
  mihomo-common = import ../../mihomo-common.nix { inherit lib; };
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = false;
    proxies = [ { name = "DNS"; type = "dns"; } ] ++ mihomo-common.mkSettings.proxies;
    rules = [ "DST-PORT,53,DNS" ] ++ mihomo-common.mkSettings.rules;
  };
  yamlFormat = pkgs.formats.yaml { };
  mihomoConfig = yamlFormat.generate "mihomo-config.yaml" settings;
in
{
  environment.etc."mihomo/config.yaml".source = mihomoConfig;

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
    processesInfo = true;
  };


  systemd.services.mihomo = {
    serviceConfig = {
      # 关键配置：赋予处理底层网络数据包和透明代理所需的内核能力
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
      ExecStartPost = "+${pkgs.tproxy}/bin/tproxy start";
      ExecStopPost = "+${pkgs.tproxy}/bin/tproxy stop";
    };
  };


}
