{ inputs, config, pkgs, ... }:

{
  imports = [
    ../common.nix
    ./modules/hyprland.nix
    ./modules/browser.nix
    ./modules/ags.nix
    ./modules/hypr.nix
    ./modules/music.nix
    ./modules/lang.nix
  ];

  # 静态配置
  xdg.configFile."keyd/app.conf".source = ../../config/keyd/app.conf;

  # 动态配置
  home.file.".local/share/fcitx5/rime" = {
    source = inputs.rime-config;
    recursive = true;
  };

  home = {
    homeDirectory = "/home/lin";
  };

  home.packages = with pkgs; [
    # gui
    inkscape
    wechat
    antigravity-fhs
    google-antigravity-cli

    jadx
    frida-tools

    # linux cli
    tproxy
    zip
    unzip
    brightnessctl
    satty
    grim
    imagemagick
    wl-clipboard
    libnotify
  ];

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_SIZE = "32";
    __ETC_ZSHRC_SOURCED = "1";
    # 修复 XWayland 程序在 force_zero_scaling 下的缩放
    #GDK_SCALE = "2";
    #QT_SCALE_FACTOR = "2";
    # JAVA_TOOL_OPTIONS = "-Dsun.java2d.uiScale=2.0";
  };

  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi
        obs-gstreamer
        obs-vkcapture
      ];
    };
  };

  services.cliphist = {
    enable = true;
  };

  systemd.user.startServices = "sd-switch";
}
