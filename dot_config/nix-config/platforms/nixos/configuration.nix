{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/mihomo.nix
    ./modules/keyd.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
    # 一直等待
    timeout = null;
    grub = {
      enable = true;
      # 指定为 EFI 模式
      efiSupport = true;
      # 自动搜索其他操作系统
      useOSProber = true;
      # 指定 EFI 分区所在的位置
      efiInstallAsRemovable = false;
      device = "nodev"; # UEFI 模式下设为 "nodev"
      # 限制显示的版本数量，防止菜单过长
      configurationLimit = 10;
    };
  };
  # 加载 Dell 专用的内核模块
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "coretemp"
    "dell_smm_hwmon"
  ];
  # 为模块添加参数以强制启用（部分 Dell 机型需要）
  boot.extraModprobeConfig = ''
    options dell_smm_hwmon ignore_dmi=1

    # 彻底禁用 Intel HDA 控制器的内核动态省电挂起（防止拔插 HDMI 时注销扬声器）
    options snd-hda-intel power_save=0 power_save_controller=N

    # 彻底禁用 SOF 音频核心的内核动态电源管理
    options snd-sof dsp_bypass=0
    options snd-sof-pci power_save=-1
  '';

  environment.sessionVariables = {
    # 告诉应用在 Wayland 下运行，避免回退到 Xwayland 导致协商失败
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";
  };

  # 开启硬件绘图支持
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # 核心：适用于 Broadwell 及以后的 iHD 驱动
      vpl-gpu-rt # 适用于 Alder Lake+ 的 QuickSync 视频处理
      libvdpau-va-gl # 可选：让 VDPAU 应用也能用 VA-API
    ];
  };

  networking = {
    networkmanager = {
      enable = true;
    };

    nftables = {
      enable = true;
    };
  };

  time.timeZone = "Asia/Shanghai";

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
        trusted-users = [ "lin" ];

        auto-optimise-store = true;

        substituters = [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };

      channel.enable = false;

      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

  environment = {
    systemPackages = with pkgs; [
      git
      neovim
      wget
      # sing-box
      mihomo
      tproxy
      keyd
      lm_sensors # 传感器驱动

      docker-compose

      virt-manager # 图形化虚拟机管理器
      qemu # QEMU 模拟器后端
      libvirt # 虚拟化 API
      dnsmasq # 默认网络 NAT 所需的依赖
      bridge-utils # 网桥工具包

      jar-launcher
    ];

    variables.EDITOR = "nvim";
  };

  virtualisation = {
    docker.enable = true;
    libvirtd = {
      enable = true;
      # 可选：如果希望 libvirt 使用 qemu-bridge-helper 启用网桥联网，需额外配置
      # qemu.vhostUserPackages = [ pkgs.qemu ];
    };
  };

  users.users = {
    lin = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "networkmanager"
        "audio"
        "docker"
        "etc"
        "keyd"
        "input"
        "libvirtd"
      ];
      shell = pkgs.zsh;
    };
  };

  services = {
    openssh.enable = true;
    upower.enable = true;
  };

  security.pam.services.hyprlock = { };

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    zsh.enable = true;
    gpu-screen-recorder.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        glibc
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  fonts = {
    packages = with pkgs; [
      adwaita-fonts
      sarasa-gothic
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      lxgw-wenkai

      roboto-mono
      vista-fonts-chs
    ];

    fontconfig = {
      antialias = true;
      hinting.enable = true;
      hinting.autohint = true;
      defaultFonts = {
        sansSerif = [
          "Microsoft YaHei"
          "Noto Sans CJK SC"
          "Source Han Sans SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "DejaVu Serif"
        ];
        monospace = [
          "Noto Sans Mono CJK SC"
          "Sarasa Mono SC"
          "DejaVu Sans Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Enable font directory for system-wide access
    fontDir.enable = true;
  };

  i18n = {
    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8"; # 或者 "zh_CN.UTF-8"
    };
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  system.stateVersion = "24.11";
}
