{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "lunar-javascript";
  version = "1.7.7";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/lunar-javascript/-/lunar-javascript-${version}.tgz";
    sha256 = "0dpa3vvqyw8zbczh9kjlvslqxswhqbgjv93q77dx24s9rawrldfi";
  };

  dontBuild = true;

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    mkdir -p $out/lib/node_modules/lunar-javascript
    cp -r package/* $out/lib/node_modules/lunar-javascript
  '';
}
