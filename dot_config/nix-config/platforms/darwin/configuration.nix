{ pkgs, ... }:

{

  imports = [
    ./modules/mihomo.nix
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.neovim
    pkgs.mihomo
    pkgs.jar-launcher
  ];



  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    gc = {
      automatic = true;
      # 替代 dates = "weekly"; 规定在每周日 (Weekday = 0) 凌晨 3:00 执行
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
  system.primaryUser = "lin";

  # Disable documentation to avoid build failures with mdbook
  documentation.enable = false;
  documentation.man.enable = false;

  users.users.lin = {
    name = "lin";
    home = "/Users/lin";
  };

  # Fonts managed by Nix
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    maple-mono.NF-CN-unhinted
  ];

  security = {
    # Add ability to used TouchID for sudo authentication
    pam.services.sudo_local.touchIdAuth = true;
    sudo.extraConfig = ''
      Defaults pwfeedback
    '';
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = true;
    };
    global = {
      brewfile = true;
    };

    brews = [
      "container"
      "pinentry-mac"
      "openvpn"
    ];

    taps = [
      "d12frosted/emacs-plus"
    ];

    casks = [
      "flameshot"
      "squirrel-app"
      "hammerspoon"
      "karabiner-elements"
      "antigravity-ide"
      "antigravity-cli"
      "brave-browser"
      "windows-app"
      "emacs-plus-app@master"
      "raycast"
      "claude-code"
    ];
  };

}
