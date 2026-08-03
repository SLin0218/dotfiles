{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage {
  pname = "jar-launcher";
  version = "1.0.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = with pkgs.lib; {
    description = "Java JAR Interactive Launcher in Rust";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
