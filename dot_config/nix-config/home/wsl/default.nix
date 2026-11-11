{
  pkgs,
  ...
}:
{
  imports = [
    ../common.nix
  ];

  dconf.enable = false;
  programs.brave = {
    enable = true;

    # 命令行启动参数
    commandLineArgs = [
      "--enable-features=TouchpadMemoryPressureMonitor" # 内存优化
      "--force-dark-mode" # 启用深色模式
    ];

  };
  home = {
    homeDirectory = "/home/lin";
    packages = with pkgs; [
      zip
      unzip
      wl-clipboard
      tproxy
      google-antigravity-cli
      qqmusic
    ];
  };

  systemd.user.startServices = "sd-switch";
}
