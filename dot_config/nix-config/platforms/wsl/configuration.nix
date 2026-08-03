{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../nixos/modules/mihomo.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "lin";
  };

  nixpkgs.config.allowUnfree = true;

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
      docker-compose
      jar-launcher
      openvpn
    ];

    variables = {
      EDITOR = "nvim";
      TERM = "xterm-256color";
      COLORTERM = "truecolor";
      GDK_SCALE = "2";
      GDK_DPI_SCALE = "1.0";
      QT_SCALE_FACTOR = "2";
    };
  };

  virtualisation = {
    docker.enable = true;
  };

  users.users = {
    lin = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
    };
  };

  programs = {
    zsh.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        glibc
      ];
    };
  };

  services = {
    pcscd.enable = true;
    openssh.enable = true;
  };

  i18n = {
    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8";
    };
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      maple-mono.NF-CN-unhinted
    ];
    fontDir.enable = true;
  };

  system.stateVersion = "24.11";
}
