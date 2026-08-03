{ ... }:

{

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ]; # 所有键盘
        settings = {
          main = {
            capslock = "overload(symbols, esc)";
          };
          symbols = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
        };
      };
    };
  };

  # Add CAP_SETGID so keyd can switch to keyd group (NixOS bug workaround)
  # https://github.com/NixOS/nixpkgs/issues/290161
  users.groups.keyd = { };

  systemd.services.keyd = {
    serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];
  };
}
