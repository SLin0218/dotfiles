{ inputs }:

[
  (final: prev:
    let
      isLinux = prev.stdenv.hostPlatform.isLinux;
      localPkgs = import ../pkgs prev;

      # Linux 专属包和重载
      linuxOverlays = {
        ags = if inputs.ags.packages ? ${prev.stdenv.hostPlatform.system}
              then inputs.ags.packages.${prev.stdenv.hostPlatform.system}.default
              else prev.ags or null;
        google-antigravity-cli = if inputs ? antigravity-nix && inputs.antigravity-nix.packages ? ${prev.stdenv.hostPlatform.system}
                                 then inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.google-antigravity-cli
                                 else null;
        inherit (localPkgs) lunar-javascript wechat tproxy;
        joker = prev.joker.overrideAttrs (oldAttrs: {
          proxyVendor = true;
          vendorHash = "sha256-4wPiuX3SsLAkvKevptgVAKdg7MR2QdouqiB+FKqdZPM=";
        });
      };

      # 跨平台通用包和重载
      commonOverlays = {
        inherit (localPkgs) t jar-launcher apifox-cli jbrsdk-17 mvn-springboot-debug;
      };
    in
    commonOverlays // (if isLinux then linuxOverlays else {})
  )
]
