{ pkgs, lib, ... }:

let
  mihomo-common = import ../../../platforms/mihomo-common.nix { inherit lib; };
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = true;
  };
  yamlFormat = pkgs.formats.yaml { };
  mihomoConfig = yamlFormat.generate "mihomo-config.yaml" settings;
in
{
  environment.etc."mihomo/config.yaml".source = mihomoConfig;
}
