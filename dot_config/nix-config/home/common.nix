{
  pkgs,
  lib,
  ...
}:
let
  isWSL =
    builtins.pathExists /proc/sys/kernel/osrelease
    && (
      let
        release = builtins.readFile /proc/sys/kernel/osrelease;
      in
      builtins.match ".*[mM][iI][cC][rR][oO][sS][oO][fF][tT].*" release != null
    );
in
{
  imports = [
    # ./modules/zsh.nix
    # ./modules/starship.nix
    # ./modules/kitty.nix
    # ./modules/wezterm.nix
    # ./modules/fastfetch.nix
    # ./modules/editor.nix
    ./modules/theme.nix
  ];

  home.file.".sqlfluff".source = ../config/sqlfluff;
  home.file.".gitconfig".source = ../config/gitconfig;

  xdg.configFile."emacs/init.el".text = ''
    ;; -*- lexical-binding: t; -*-
    (setq nix-librime-path "${pkgs.librime}")
    (setq nix-rime-share-data-path "${pkgs.rime-data}")
    (setq nix-jbrsdk-path "${pkgs.jbrsdk-17}")
    (setq nix-openjdk21-path "${pkgs.openjdk21}")
    (add-to-list 'load-path "~/.config/slin-emacs")
    (require 'slin-emacs)
  '';

  home = {
    username = "lin";
    stateVersion = "25.11";
  };

  home.packages =
    with pkgs;
    [
      # common cli
      fd
      jq
      nixd
      nixfmt
      ripgrep
      nodejs
      pnpm
      delta
      fzf
      mycli
      httpie
      pandoc
      (texlive.combine {
        inherit (texlive) scheme-medium collection-langchinese collection-latexextra;
      })
      nmap
      bind.dnsutils
      fastfetch

      # rime
      librime

      # java & build tools
      (lib.hiPrio jbrsdk-17)
      (lib.lowPrio openjdk21)
      maven
      mvn-springboot-debug

      # translate
      t
      mpc
      mpv
      android-tools

      gnupg

      git-crypt

      chezmoi

      # build tools
      gdb
      python3
      cmake
      gnumake
      gcc

      # gui
      jetbrains.idea
    ]
    # gui
    ++ lib.optionals (!isWSL) [
      wezterm
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      emacs-pgtk
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pinentry-gnome3
    ];

  home.sessionVariables = {
    EDITOR = "nvim";
    JAVA_HOME = "${pkgs.jbrsdk-17.home or pkgs.jbrsdk-17}";
    JAVA21_HOME = "${pkgs.openjdk21}";
  };

  programs = {
    home-manager.enable = true;
    btop.enable = true;
    eza.enable = true;
    bat.enable = true;
  };
}
