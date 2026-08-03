{ pkgs, lib, config, ...}:

{
  catppuccin = {
    enable = true;      # 默认为所有支持的应用开启
    autoEnable = true;
    flavor = "mocha";   # latte, frappe, macchiato, mocha
    accent = "lavender"; # blue, flamingo, green, pink, etc.
    hyprlock = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      useDefaultConfig = false;
    };
    fcitx5 = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      enableRounded = true;
    };
  };
  gtk = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        variant = "mocha";
        size = "standard";
      };
    };
    gtk4.theme = config.gtk.theme;

    #iconTheme = {
    #  name = "Papirus-Dark";
    #  package = pkgs.catppuccin-papirus-folders.override {
    #    flavor = "macchiato";
    #    accent = "lavender";
    #  };
    #};

    cursorTheme = {
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
}
