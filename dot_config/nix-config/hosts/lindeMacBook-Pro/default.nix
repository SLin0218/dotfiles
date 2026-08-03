{ ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "lindeMacBook-Pro";
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    brews = [
    ];

    casks = [
      "android-studio"
      "stats"
      "steam"
      "readdle-spark"
    ];
  };
}
