{ inputs, config, pkgs, ... }:
{
  imports = [
    ../common.nix
  ];

  dconf.enable = false;

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
