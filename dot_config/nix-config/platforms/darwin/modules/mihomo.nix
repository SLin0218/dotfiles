{ pkgs, ... }:

{
  launchd.daemons.mihomo = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        "/etc/mihomo/"
      ];
      KeepAlive = {
        NetworkState = true;
      };
      RunAtLoad = true;
      StandardOutPath = "/var/log/mihomo/info.log";
      StandardErrorPath = "/var/log/mihomo/error.log";
    };
  };
}
