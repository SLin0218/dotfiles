{
  description = "my nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ohmyzsh = {
      url = "github:ohmyzsh/ohmyzsh";
      flake = false;
    };

    rime-config = {
      url = "github:SLin0218/rime-config";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      # 统一管理所有的 Overlay
      overlays = import ./overlays { inherit inputs; };
    in
    {
      # 命令行直接使用的包 (nix build .#xxx)
      packages = { };

      nixosConfigurations = {
        inspiron-lin = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./platforms/nixos/configuration.nix
            ./hosts/inspiron-lin

            # 直接引用上面定义的统一 Overlay
            { nixpkgs.overlays = overlays; }

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.lin = {
                imports = [
                  ./home/nixos
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.ags.homeManagerModules.default
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };

        DESKTOP-I8CKT04 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.nixos-wsl.nixosModules.default
            ./platforms/wsl/configuration.nix
            ./hosts/DESKTOP-I8CKT04

            # 直接引用上面定义的统一 Overlay
            { nixpkgs.overlays = overlays; }

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.lin = {
                imports = [
                  ./home/wsl
                  inputs.catppuccin.homeModules.catppuccin
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };

        wsl-home-desktop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            inputs.nixos-wsl.nixosModules.default
            ./platforms/wsl/configuration.nix
            ./hosts/wsl-home-desktop

            # 直接引用上面定义的统一 Overlay
            { nixpkgs.overlays = overlays; }

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.lin = {
                imports = [
                  ./home/wsl
                  inputs.catppuccin.homeModules.catppuccin
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

      darwinConfigurations = {
        fcdeMac-mini = inputs.darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [

            ./platforms/darwin/configuration.nix
            ./hosts/fcdeMac-mini

            # 直接引用上面定义的统一 Overlay
            { nixpkgs.overlays = overlays; }

            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-nix";
              home-manager.users.lin = {
                imports = [
                  ./home/darwin
                  ./hosts/fcdeMac-mini/home.nix
                  inputs.catppuccin.homeModules.catppuccin
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
        lindeMacBook-Pro = inputs.darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./platforms/darwin/configuration.nix
            ./hosts/lindeMacBook-Pro

            # 直接引用上面定义的统一 Overlay
            { nixpkgs.overlays = overlays; }

            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-nix";
              home-manager.users.lin = {
                imports = [
                  ./home/darwin
                  ./hosts/lindeMacBook-Pro/home.nix
                  inputs.catppuccin.homeModules.catppuccin
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

    };
}
