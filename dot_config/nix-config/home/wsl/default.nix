{ inputs, config, pkgs, ... }:
{
  imports = [
    ../common.nix
  ];

  dconf.enable = false;

  # 动态配置
  home.file.".local/share/fcitx5/rime" = {
    source = inputs.rime-config;
    recursive = true;
  };

  home = {
    homeDirectory = "/home/lin";
  };

  home.packages = with pkgs; [
    zip
    unzip
    wl-clipboard
    tproxy
    google-antigravity-cli
  ];

  systemd.user.startServices = "sd-switch";
}
