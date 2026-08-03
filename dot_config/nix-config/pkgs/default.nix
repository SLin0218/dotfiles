pkgs: {
  lunar-javascript = import ./lunar-javascript.nix { inherit pkgs; };
  wechat = import ./wechat { inherit pkgs; };
  tproxy = import ./tproxy.nix { inherit pkgs; };
  t = import ./translate { inherit pkgs; };
  jar-launcher = import ./jar-launcher { inherit pkgs; };
  apifox-cli = import ./apifox-cli { inherit pkgs; };
  jbrsdk-17 = import ./jbrsdk-17.nix { inherit pkgs; };
  mvn-springboot-debug = import ./mvn-springboot-debug.nix { inherit pkgs; };
}
