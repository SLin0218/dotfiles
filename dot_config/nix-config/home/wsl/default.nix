{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../common.nix
    ../modules/lang.nix
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

  # 使用 3lelele/wslg 补丁版 WSLg 时已启用 allow-external=true 与 text-input-v3 桥接，
  # fcitx5 可作为 Wayland 原生输入法正常运行。
  # 随 default.target 自启动，并注入 Wayland 与 Display 环境变量。
  systemd.user.services.fcitx5-daemon = {
    Unit = {
      Description = "Fcitx5 input method editor";
      PartOf = lib.mkForce [ ];
      After = lib.mkForce [ ];
    };
    Service = {
      ExecStart = lib.mkForce "${config.i18n.inputMethod.package}/bin/fcitx5";
      Environment = [
        "WAYLAND_DISPLAY=wayland-0"
        "DISPLAY=:0"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
      Restart = "on-failure";
    };
    Install = {
      WantedBy = lib.mkForce [ "default.target" ];
    };
  };

  systemd.user.startServices = "sd-switch";
}
