{ inputs, pkgs, config, lib, ... }:
let
  mySystem = pkgs.stdenv.hostPlatform.system;
  agsPath = "${config.home.homeDirectory}/.config/nix-config/config/ags/";
in
{

  xdg.configFile."ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;

  home.activation.linkAgsModules = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ ! -d ${agsPath}/node_modules ]];then
      $DRY_RUN_CMD mkdir -p ${agsPath}/node_modules
    fi
    rm ${agsPath}/node_modules/lunar-javascript
    rm ${agsPath}/node_modules/ags
    $DRY_RUN_CMD ln -sf ${pkgs.lunar-javascript}/lib/node_modules/lunar-javascript $VERBOSE_ARG ${agsPath}/node_modules/
    $DRY_RUN_CMD ln -sf ${pkgs.ags}/share/ags/js/lib $VERBOSE_ARG ${agsPath}/node_modules/ags
  '';

  programs.ags = {
    enable = true;

    # configDir = ../../config/ags;

    extraPackages = with pkgs; [
      inputs.astal.packages.${mySystem}.io
      inputs.astal.packages.${mySystem}.astal4

      inputs.astal.packages.${mySystem}.battery
      inputs.astal.packages.${mySystem}.hyprland
      inputs.astal.packages.${mySystem}.tray
      inputs.astal.packages.${mySystem}.notifd
      inputs.astal.packages.${mySystem}.wireplumber
      inputs.astal.packages.${mySystem}.network
      inputs.astal.packages.${mySystem}.bluetooth
      inputs.astal.packages.${mySystem}.apps

      libadwaita
    ];
  };
}
