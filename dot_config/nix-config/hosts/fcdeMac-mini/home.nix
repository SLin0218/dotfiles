{ pkgs, ... }:
{
  home.packages = with pkgs; [
    apifox-cli
  ];
}
