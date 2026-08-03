{ lib, ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "fcdeMac-mini";
  nixpkgs.hostPlatform = "aarch64-darwin";

  # 自动进行垃圾回收
  nix.gc = lib.mkForce {
    automatic = true;
    # 每周日凌晨 2 点清理
    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
    # 只保留 1 天内的历史
    options = "--delete-older-than 1d";
  };

  # 每次构建系统时，自动合并重复文件
  nix.settings.auto-optimise-store = true;

  homebrew = {
    casks = [
    ];
  };
}
