{ pkgs, ... }:

{
  launchd.daemons.mihomo = {
    command = "${pkgs.mihomo}/bin/mihomo -d /etc/mihomo/";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/mihomo/info.log";
      StandardErrorPath = "/var/log/mihomo/error.log";
    };
  };
}

