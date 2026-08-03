{ pkgs, lib, ... }:

let
  mihomo-common = import ../../../platforms/mihomo-common.nix { inherit lib; };
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = true;
    proxies = [
      {
        name = "TW";
        type = "http";
        server = "tw-vpn.container";
        port = 8888;
      }
    ]
    ++ mihomo-common.mkSettings.proxies;
    rules = [ "IP-CIDR,172.16.90.0/24,TW" ] ++ mihomo-common.mkSettings.rules;
  };
  yamlFormat = pkgs.formats.yaml { };
  mihomoConfig = yamlFormat.generate "mihomo-config.yaml" settings;
in
{
  environment.etc."mihomo/config.yaml".source = mihomoConfig;
}
